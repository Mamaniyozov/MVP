import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.goals.models import Goal


@pytest.mark.django_db
def test_create_goal():
    user = User.objects.create_user(username="g@example.com", email="g@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/goals/", {"name": "Yangi mashina", "target_amount": "50000000", "current_amount": "1000000"}
    )

    assert response.status_code == 201
    assert response.data["name"] == "Yangi mashina"


@pytest.mark.django_db
def test_list_update_delete_own_goal():
    user = User.objects.create_user(username="g2@example.com", email="g2@example.com", password="Str0ngPass!1")
    goal = Goal.objects.create(user=user, name="Uy", target_amount="100000000", current_amount="20000000")

    client = APIClient()
    client.force_authenticate(user=user)

    list_response = client.get("/api/v1/goals/")
    assert list_response.status_code == 200
    ids = {item["id"] for item in list_response.data}
    assert ids == {goal.id}

    detail_url = f"/api/v1/goals/{goal.id}/"
    patch_response = client.patch(detail_url, {"name": "Uy (yangilangan)"})
    assert patch_response.status_code == 200
    assert patch_response.data["name"] == "Uy (yangilangan)"

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 204
    assert not Goal.objects.filter(id=goal.id).exists()


@pytest.mark.django_db
def test_user_cannot_see_or_modify_other_users_goal():
    user = User.objects.create_user(username="g3@example.com", email="g3@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="g4@example.com", email="g4@example.com", password="Str0ngPass!1")
    other_goal = Goal.objects.create(user=other, name="Other's Goal", target_amount="1000000", current_amount="0")

    client = APIClient()
    client.force_authenticate(user=user)

    detail_url = f"/api/v1/goals/{other_goal.id}/"

    get_response = client.get(detail_url)
    assert get_response.status_code == 404

    patch_response = client.patch(detail_url, {"name": "Hacked"})
    assert patch_response.status_code == 404

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 404

    add_progress_response = client.post(f"{detail_url}add-progress/", {"amount": "100"})
    assert add_progress_response.status_code == 404

    assert Goal.objects.filter(id=other_goal.id, name="Other's Goal").exists()


@pytest.mark.django_db
def test_add_progress_normal_case():
    user = User.objects.create_user(username="g5@example.com", email="g5@example.com", password="Str0ngPass!1")
    goal = Goal.objects.create(user=user, name="Sayohat", target_amount="1000000", current_amount="200000")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(f"/api/v1/goals/{goal.id}/add-progress/", {"amount": "300000"})

    assert response.status_code == 200
    assert response.data["current_amount"] == "500000.00"
    assert response.data["progress_percent"] == 50.0

    goal.refresh_from_db()
    assert goal.current_amount == 500000


@pytest.mark.django_db
def test_add_progress_exceeding_target_returns_error():
    user = User.objects.create_user(username="g6@example.com", email="g6@example.com", password="Str0ngPass!1")
    goal = Goal.objects.create(user=user, name="Mashina", target_amount="1000000", current_amount="900000")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(f"/api/v1/goals/{goal.id}/add-progress/", {"amount": "200000"})

    assert response.status_code == 400

    goal.refresh_from_db()
    assert goal.current_amount == 900000


@pytest.mark.django_db
def test_add_progress_negative_amount_returns_error():
    user = User.objects.create_user(username="g7@example.com", email="g7@example.com", password="Str0ngPass!1")
    goal = Goal.objects.create(user=user, name="Mashina", target_amount="1000000", current_amount="100000")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(f"/api/v1/goals/{goal.id}/add-progress/", {"amount": "-50000"})

    assert response.status_code == 400
    assert "amount" in response.data

    goal.refresh_from_db()
    assert goal.current_amount == 100000
