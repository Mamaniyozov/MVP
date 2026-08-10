import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from apps.notifications.models import Notification, UserDevice


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def create_user():
    def _create_user(username, email, password="Str0ngPass!1"):
        return User.objects.create_user(username=username, email=email, password=password)
    return _create_user


@pytest.mark.django_db
def test_create_device_token(api_client, create_user):
    user = create_user("dev1@test.com", "dev1@test.com")
    api_client.force_authenticate(user=user)

    response = api_client.post("/api/v1/notifications/device/", {
        "device_id": "test-device-uuid-123",
        "fcm_token": "fcm-token-12345"
    })

    assert response.status_code == 201
    assert UserDevice.objects.filter(user=user, device_id="test-device-uuid-123").exists()


@pytest.mark.django_db
def test_get_notifications(api_client, create_user):
    user = create_user("notif1@test.com", "notif1@test.com")
    Notification.objects.create(user=user, title="Test", message="Msg")
    
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/v1/notifications/")
    
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["title"] == "Test"


@pytest.mark.django_db
def test_mark_notification_as_read(api_client, create_user):
    user = create_user("notif2@test.com", "notif2@test.com")
    notification = Notification.objects.create(user=user, title="Test", message="Msg")
    
    api_client.force_authenticate(user=user)
    response = api_client.post(f"/api/v1/notifications/{notification.id}/read/")
    
    assert response.status_code == 200
    notification.refresh_from_db()
    assert notification.is_read is True


@pytest.mark.django_db
def test_goal_completion_sends_notification(api_client, create_user):
    user = create_user("goal@test.com", "goal@test.com")
    api_client.force_authenticate(user=user)
    
    # Create goal
    from apps.goals.models import Goal
    goal = Goal.objects.create(user=user, name="Buy a car", target_amount=1000, current_amount=900)
    
    # Add progress to reach target
    response = api_client.post(f"/api/v1/goals/{goal.id}/add-progress/", {"amount": 100})
    assert response.status_code == 200
    
    # Check if notification was created
    assert Notification.objects.filter(user=user, notification_type="goal").exists()
