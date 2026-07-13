import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.cards.models import Card


@pytest.mark.django_db
def test_create_card():
    user = User.objects.create_user(username="c@example.com", email="c@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post("/api/v1/cards/", {"name": "Visa", "last4": "1234"})

    assert response.status_code == 201
    assert response.data["name"] == "Visa"


@pytest.mark.django_db
def test_list_update_delete_own_card():
    user = User.objects.create_user(username="c2@example.com", email="c2@example.com", password="Str0ngPass!1")
    card = Card.objects.create(user=user, name="Humo", last4="4321")

    client = APIClient()
    client.force_authenticate(user=user)

    list_response = client.get("/api/v1/cards/")
    assert list_response.status_code == 200
    ids = {item["id"] for item in list_response.data}
    assert ids == {card.id}

    detail_url = f"/api/v1/cards/{card.id}/"
    patch_response = client.patch(detail_url, {"name": "Humo Renamed"})
    assert patch_response.status_code == 200
    assert patch_response.data["name"] == "Humo Renamed"

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 204
    assert not Card.objects.filter(id=card.id).exists()


@pytest.mark.django_db
def test_user_cannot_see_or_modify_other_users_card():
    user = User.objects.create_user(username="c3@example.com", email="c3@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="c4@example.com", email="c4@example.com", password="Str0ngPass!1")
    other_card = Card.objects.create(user=other, name="Other's Card")

    client = APIClient()
    client.force_authenticate(user=user)

    list_response = client.get("/api/v1/cards/")
    assert other_card.id not in {item["id"] for item in list_response.data}

    detail_url = f"/api/v1/cards/{other_card.id}/"

    get_response = client.get(detail_url)
    assert get_response.status_code == 404

    patch_response = client.patch(detail_url, {"name": "Hacked"})
    assert patch_response.status_code == 404

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 404

    assert Card.objects.filter(id=other_card.id, name="Other's Card").exists()
