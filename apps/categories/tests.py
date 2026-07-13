import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.categories.models import Category


def _extract_results(data):
    return data["results"] if isinstance(data, dict) and "results" in data else data


@pytest.mark.django_db
def test_user_can_only_see_own_categories():
    user_a = User.objects.create_user(username="a@example.com", email="a@example.com", password="Str0ngPass!1")
    user_b = User.objects.create_user(username="b@example.com", email="b@example.com", password="Str0ngPass!1")

    client = APIClient()
    client.force_authenticate(user=user_a)

    response = client.get("/api/v1/categories/")

    assert response.status_code == 200
    returned_ids = {item["id"] for item in _extract_results(response.data)}
    own_ids = set(user_a.categories.values_list("id", flat=True))
    other_ids = set(user_b.categories.values_list("id", flat=True))

    assert returned_ids == own_ids
    assert not returned_ids & other_ids


@pytest.mark.django_db
def test_global_default_category_is_visible_to_everyone():
    user = User.objects.create_user(username="c@example.com", email="c@example.com", password="Str0ngPass!1")
    global_category = Category.objects.create(user=None, name="Global", type="expense", is_default=True)

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/categories/")

    assert response.status_code == 200
    returned_ids = {item["id"] for item in _extract_results(response.data)}
    assert global_category.id in returned_ids


@pytest.mark.django_db
def test_cannot_update_or_delete_global_default_category():
    user = User.objects.create_user(username="d@example.com", email="d@example.com", password="Str0ngPass!1")
    global_category = Category.objects.create(user=None, name="Global", type="expense", is_default=True)

    client = APIClient()
    client.force_authenticate(user=user)

    detail_url = f"/api/v1/categories/{global_category.id}/"

    patch_response = client.patch(detail_url, {"name": "Hacked"})
    assert patch_response.status_code == 403

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 403

    global_category.refresh_from_db()
    assert global_category.name == "Global"


@pytest.mark.django_db
def test_type_filter():
    user = User.objects.create_user(username="e@example.com", email="e@example.com", password="Str0ngPass!1")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/categories/", {"type": "income"})

    assert response.status_code == 200
    returned_types = {item["type"] for item in _extract_results(response.data)}
    assert returned_types == {"income"}


@pytest.mark.django_db
def test_user_cannot_see_or_modify_other_users_category():
    user = User.objects.create_user(username="f@example.com", email="f@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="g@example.com", email="g@example.com", password="Str0ngPass!1")
    other_category = Category.objects.filter(user=other, type="expense").first()

    client = APIClient()
    client.force_authenticate(user=user)

    detail_url = f"/api/v1/categories/{other_category.id}/"

    get_response = client.get(detail_url)
    assert get_response.status_code == 404

    patch_response = client.patch(detail_url, {"name": "Hacked"})
    assert patch_response.status_code == 404

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 404
