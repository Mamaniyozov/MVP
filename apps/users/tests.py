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


@pytest.mark.django_db
def test_change_password_success(client):
    user = User.objects.create_user(
        username="change@example.com", email="change@example.com", password="OldStr0ngPass!1"
    )
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/auth/change-password/",
        {"old_password": "OldStr0ngPass!1", "new_password": "NewStr0ngPass!2"},
    )

    assert response.status_code == 200
    user.refresh_from_db()
    assert user.check_password("NewStr0ngPass!2")


@pytest.mark.django_db
def test_change_password_wrong_old_password_fails(client):
    user = User.objects.create_user(
        username="wrong_old@example.com", email="wrong_old@example.com", password="OldStr0ngPass!1"
    )
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/auth/change-password/",
        {"old_password": "IncorrectPassword!1", "new_password": "NewStr0ngPass!2"},
    )

    assert response.status_code == 400
    assert "old_password" in response.data


@pytest.mark.django_db
def test_password_reset_flow_success(client):
    user = User.objects.create_user(
        username="reset@example.com", email="reset@example.com", password="OldStr0ngPass!1"
    )

    req_response = client.post("/api/v1/auth/password-reset/", {"email": "reset@example.com"})
    assert req_response.status_code == 200
    assert "uid" in req_response.data
    assert "token" in req_response.data

    uid = req_response.data["uid"]
    token = req_response.data["token"]

    confirm_response = client.post(
        "/api/v1/auth/password-reset/confirm/",
        {"uid": uid, "token": token, "new_password": "NewStr0ngPass!99"},
    )
    assert confirm_response.status_code == 200

    user.refresh_from_db()
    assert user.check_password("NewStr0ngPass!99")


@pytest.mark.django_db
def test_password_reset_confirm_invalid_token_fails(client):
    user = User.objects.create_user(
        username="invalid_reset@example.com", email="invalid_reset@example.com", password="OldStr0ngPass!1"
    )

    req_response = client.post("/api/v1/auth/password-reset/", {"email": "invalid_reset@example.com"})
    uid = req_response.data["uid"]

    confirm_response = client.post(
        "/api/v1/auth/password-reset/confirm/",
        {"uid": uid, "token": "invalid-token-123", "new_password": "NewStr0ngPass!99"},
    )
    assert confirm_response.status_code == 400
    assert "token" in confirm_response.data


@pytest.mark.django_db
def test_idempotency_middleware_user_isolation(client):
    from rest_framework_simplejwt.tokens import RefreshToken

    user_a = User.objects.create_user(username="usera@example.com", email="usera@example.com", password="Pass!1userA")
    user_b = User.objects.create_user(username="userb@example.com", email="userb@example.com", password="Pass!1userB")

    token_a = str(RefreshToken.for_user(user_a).access_token)
    token_b = str(RefreshToken.for_user(user_b).access_token)

    shared_key = "TXN-KEY-100"

    # User A creates a category with shared idempotency key
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token_a}", HTTP_IDEMPOTENCY_KEY=shared_key)
    res_a1 = client.post("/api/v1/categories/", {"name": "User A Category", "type": "expense"})
    assert res_a1.status_code == 201
    assert res_a1.data["name"] == "User A Category"

    # User A re-sends the same request -> gets cached HIT-Idempotent response
    res_a2 = client.post("/api/v1/categories/", {"name": "User A Category", "type": "expense"})
    assert res_a2.status_code == 201
    assert res_a2.headers.get("X-Cache-Lookup") == "HIT-Idempotent"

    # User B sends request with the SAME idempotency key -> MUST NOT get User A's response!
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token_b}", HTTP_IDEMPOTENCY_KEY=shared_key)
    res_b1 = client.post("/api/v1/categories/", {"name": "User B Category", "type": "expense"})
    assert res_b1.status_code == 201
    assert res_b1.data["name"] == "User B Category"
    assert res_b1.headers.get("X-Cache-Lookup") is None


@pytest.mark.django_db
def test_idempotency_middleware_invalid_token_fallback(client):
    from config.middleware import IdempotencyMiddleware
    from django.test import RequestFactory

    factory = RequestFactory()
    req = factory.post("/api/v1/categories/", HTTP_AUTHORIZATION="Bearer invalid.jwt.token", HTTP_IDEMPOTENCY_KEY="ANON-KEY-1")
    middleware = IdempotencyMiddleware(lambda r: None)
    
    # Verify _get_user_identity safely falls back to "anon" when token is invalid without raising an exception
    identity = middleware._get_user_identity(req)
    assert identity == "anon"


@pytest.mark.django_db
def test_idempotency_middleware_ignores_get(client):
    from rest_framework_simplejwt.tokens import RefreshToken

    user = User.objects.create_user(username="getuser@example.com", email="getuser@example.com", password="Pass!1get")
    token = str(RefreshToken.for_user(user).access_token)

    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}", HTTP_IDEMPOTENCY_KEY="GET-KEY")
    res1 = client.get("/api/v1/categories/")
    assert res1.status_code == 200
    assert res1.headers.get("X-Cache-Lookup") is None

    res2 = client.get("/api/v1/categories/")
    assert res2.status_code == 200
    assert res2.headers.get("X-Cache-Lookup") is None


@pytest.mark.django_db
def test_health_check_endpoint(client):
    response = client.get("/api/v1/health/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["database"] == "connected"





