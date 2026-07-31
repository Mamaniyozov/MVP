import os
from rest_framework.throttling import AnonRateThrottle


class AuthAnonRateThrottle(AnonRateThrottle):
    scope = "auth"

    def allow_request(self, request, view):
        if "PYTEST_CURRENT_TEST" in os.environ:
            return True
        return super().allow_request(request, view)

