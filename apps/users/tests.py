import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.categories.models import Category


@pytest.fixture
def client():
    return APIClient()


@pytest.mark.django_db
def test_register_success(client):
    response = client.post(
        "/api/v1/auth/register/",
        {"email": "new@example.com", "password": "Str0ngPass!1", "password2": "Str0ngPass!1"},
    )

    assert response.status_code == 201
    assert User.objects.filter(email="new@example.com").exists()


@pytest.mark.django_db
def test_register_duplicate_email_fails(client):
    User.objects.create_user(username="dup@example.com", email="dup@example.com", password="Str0ngPass!1")

    response = client.post(
        "/api/v1/auth/register/",
        {"email": "dup@example.com", "password": "Str0ngPass!1", "password2": "Str0ngPass!1"},
    )

    assert response.status_code == 400
    assert "email" in response.data


@pytest.mark.django_db
def test_register_password_mismatch_fails(client):
    response = client.post(
        "/api/v1/auth/register/",
        {"email": "mismatch@example.com", "password": "Str0ngPass!1", "password2": "Different!1"},
    )

    assert response.status_code == 400


@pytest.mark.django_db
def test_login_success(client):
    User.objects.create_user(username="login@example.com", email="login@example.com", password="Str0ngPass!1")

    response = client.post(
        "/api/v1/auth/login/", {"email": "login@example.com", "password": "Str0ngPass!1"}
    )

    assert response.status_code == 200
    assert "access" in response.data
    assert "refresh" in response.data


@pytest.mark.django_db
def test_login_wrong_password_fails(client):
    User.objects.create_user(username="wrong@example.com", email="wrong@example.com", password="Str0ngPass!1")

    response = client.post(
        "/api/v1/auth/login/", {"email": "wrong@example.com", "password": "WrongPass!1"}
    )

    assert response.status_code == 400


@pytest.mark.django_db
def test_register_creates_default_categories(client):
    client.post(
        "/api/v1/auth/register/",
        {"email": "cats@example.com", "password": "Str0ngPass!1", "password2": "Str0ngPass!1"},
    )

    user = User.objects.get(email="cats@example.com")
    categories = Category.objects.filter(user=user, is_default=True)

    assert categories.filter(type="expense").count() == 9
    assert categories.filter(type="income").count() == 2
    assert hasattr(user, "profile")


@pytest.mark.django_db
def test_token_refresh(client):
    client.post(
        "/api/v1/auth/register/",
        {"email": "refresh@example.com", "password": "Str0ngPass!1", "password2": "Str0ngPass!1"},
    )
    login_response = client.post(
        "/api/v1/auth/login/", {"email": "refresh@example.com", "password": "Str0ngPass!1"}
    )
    refresh_token = login_response.data["refresh"]

    response = client.post("/api/v1/auth/refresh/", {"refresh": refresh_token})

    assert response.status_code == 200
    assert "access" in response.data
