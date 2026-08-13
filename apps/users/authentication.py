from django.conf import settings
from rest_framework_simplejwt.authentication import JWTAuthentication

class CookieJWTAuthentication(JWTAuthentication):
    def authenticate(self, request):
        # Try to get the token from standard Authorization header first
        header = self.get_header(request)
        if header is None:
            # If not in header, fallback to HttpOnly cookie
            raw_token = request.COOKIES.get(getattr(settings, 'SIMPLE_JWT', {}).get('AUTH_COOKIE', 'access_token'))
            if raw_token is not None:
                # Need to convert to bytes for simplejwt
                raw_token = raw_token.encode("utf-8")
        else:
            raw_token = self.get_raw_token(header)
            
        if raw_token is None:
            return None

        validated_token = self.get_validated_token(raw_token)

        return self.get_user(validated_token), validated_token
