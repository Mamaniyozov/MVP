import json
import uuid
from django.core.cache import cache
from django.http import HttpResponse


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

    def __call__(self, request):
        if request.method not in ("POST", "PUT", "PATCH"):
            return self.get_response(request)

        idempotency_key = request.META.get("HTTP_IDEMPOTENCY_KEY")
        if not idempotency_key:
            return self.get_response(request)

        user_id = request.user.id if request.user.is_authenticated else "anon"
        cache_key = f"idempotency_{user_id}_{idempotency_key}"

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
