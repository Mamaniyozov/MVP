import hashlib
import json
import uuid
from django.core.cache import cache
from django.http import HttpResponse
from rest_framework_simplejwt.authentication import JWTAuthentication


class RequestIDMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = request.META.get("HTTP_X_REQUEST_ID") or str(uuid.uuid4())
        request.request_id = request_id
        response = self.get_response(request)
        response["X-Request-ID"] = request_id
        return response


class IdempotencyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self.jwt_authenticator = JWTAuthentication()

    def _get_user_identity(self, request):
        # 1. Check if Django session/middleware already authenticated the user
        if hasattr(request, "user") and request.user and request.user.is_authenticated:
            return f"user_{request.user.id}"

        # 2. Check if JWT Authorization header is present
        auth_header = request.META.get("HTTP_AUTHORIZATION")
        if auth_header and isinstance(auth_header, str) and auth_header.startswith("Bearer "):
            try:
                authenticated = self.jwt_authenticator.authenticate(request)
                if authenticated is not None:
                    user, _ = authenticated
                    if user and user.is_authenticated:
                        request.user = user
                        return f"user_{user.id}"
            except Exception:
                # Invalid or expired token — fall back safely to anonymous namespace
                pass

        return "anon"

    def __call__(self, request):
        if request.method not in ("POST", "PUT", "PATCH"):
            return self.get_response(request)

        idempotency_key = request.META.get("HTTP_IDEMPOTENCY_KEY")
        if not idempotency_key:
            return self.get_response(request)

        user_identity = self._get_user_identity(request)
        raw_key = str(idempotency_key).strip()
        key_hash = hashlib.sha256(raw_key.encode("utf-8")).hexdigest()[:32]
        cache_key = f"idempotency_{user_identity}_{key_hash}"

        cached_response_data = cache.get(cache_key)
        if cached_response_data:
            response = HttpResponse(
                content=cached_response_data["content"],
                status=cached_response_data["status"],
                content_type=cached_response_data["content_type"],
            )
            response["X-Cache-Lookup"] = "HIT-Idempotent"
            return response

        response = self.get_response(request)

        # Cache successful response for 300 seconds
        if 200 <= response.status_code < 300:
            cache.set(
                cache_key,
                {
                    "content": response.content.decode("utf-8") if isinstance(response.content, bytes) else response.content,
                    "status": response.status_code,
                    "content_type": response.get("Content-Type", "application/json"),
                },
                timeout=300,
            )

        return response

