from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView, TokenBlacklistView
from django.conf import settings
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit

from apps.users.serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    OTPRequestSerializer,
    OTPVerifySerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    PhoneRegisterSerializer,
    RegisterSerializer,
    UserSerializer,
)
from apps.users.throttling import AuthAnonRateThrottle


class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


def set_auth_cookies(response: Response, access_token: str, refresh_token: str) -> Response:
    """Helper to set HttpOnly cookies for JWT tokens"""
    cookie_settings = getattr(settings, 'SIMPLE_JWT', {})
    
    response.set_cookie(
        key=cookie_settings.get('AUTH_COOKIE', 'access_token'),
        value=access_token,
        max_age=cookie_settings.get('ACCESS_TOKEN_LIFETIME').total_seconds() if cookie_settings.get('ACCESS_TOKEN_LIFETIME') else 3600,
        secure=settings.SESSION_COOKIE_SECURE,
        httponly=True,
        samesite=cookie_settings.get('AUTH_COOKIE_SAMESITE', 'Lax'),
    )
    response.set_cookie(
        key=cookie_settings.get('REFRESH_COOKIE', 'refresh_token'),
        value=refresh_token,
        max_age=cookie_settings.get('REFRESH_TOKEN_LIFETIME').total_seconds() if cookie_settings.get('REFRESH_TOKEN_LIFETIME') else 86400,
        secure=settings.SESSION_COOKIE_SECURE,
        httponly=True,
        samesite=cookie_settings.get('AUTH_COOKIE_SAMESITE', 'Lax'),
    )
    return response


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    @method_decorator(ratelimit(key='ip', rate='5/m', method='POST', block=True))
    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        
        from django_otp.plugins.otp_totp.models import TOTPDevice
        device = TOTPDevice.objects.filter(user=user, name="default", confirmed=True).first()
        if device:
            from django.core.signing import TimestampSigner
            signer = TimestampSigner()
            temp_token = signer.sign(str(user.id))
            return Response({"mfa_required": True, "temp_token": temp_token}, status=status.HTTP_200_OK)

        refresh = RefreshToken.for_user(user)
        response = Response(
            {"detail": "Muvaffaqiyatli kirdingiz."},
            status=status.HTTP_200_OK,
        )
        return set_auth_cookies(response, str(refresh.access_token), str(refresh))


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "Parol muvaffaqiyatli o'zgartirildi."}, status=status.HTTP_200_OK)


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reset_data = serializer.save()
        response_data = {"detail": "Parolni tiklash havolasi yuborildi."}
        if reset_data:
            response_data.update({"uid": reset_data["uid"], "token": reset_data["token"]})
        return Response(response_data, status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "Parol muvaffaqiyatli tiklandi va o'zgartirildi."}, status=status.HTTP_200_OK)


class PhoneRegisterView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PhoneRegisterSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        profile = serializer.save()
        return Response(
            {"detail": "Telefon raqami muvaffaqiyatli bog'landi.", "phone_number": profile.phone_number},
            status=status.HTTP_200_OK,
        )


class OTPRequestView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    @method_decorator(ratelimit(key='ip', rate='5/m', method='POST', block=True))
    def post(self, request):
        from apps.users.otp import generate_otp

        serializer = OTPRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]

        try:
            result = generate_otp(phone_number)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_429_TOO_MANY_REQUESTS)

        # MVP: OTP is returned in the response for testing. Remove in production.
        return Response(
            {"detail": "OTP yuborildi.", "otp": result["otp"]},
            status=status.HTTP_200_OK,
        )


class OTPVerifyView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    @method_decorator(ratelimit(key='ip', rate='10/m', method='POST', block=True))
    def post(self, request):
        from apps.users.models import UserProfile
        from apps.users.otp import verify_otp

        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        otp_code = serializer.validated_data["otp"]

        try:
            verify_otp(phone_number, otp_code)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        try:
            profile = UserProfile.objects.select_related("user").get(phone_number=phone_number)
        except UserProfile.DoesNotExist:
            return Response(
                {"detail": "Bu telefon raqamiga tegishli foydalanuvchi topilmadi."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not profile.is_phone_verified:
            profile.is_phone_verified = True
            profile.save()

        user = profile.user
        refresh = RefreshToken.for_user(user)
        response = Response(
            {"detail": "Muvaffaqiyatli kirdingiz."},
            status=status.HTTP_200_OK,
        )
        return set_auth_cookies(response, str(refresh.access_token), str(refresh))


class CookieTokenRefreshView(TokenRefreshView):
    throttle_classes = [AuthAnonRateThrottle]

    def post(self, request, *args, **kwargs):
        cookie_settings = getattr(settings, 'SIMPLE_JWT', {})
        refresh_cookie_name = cookie_settings.get('REFRESH_COOKIE', 'refresh_token')
        
        # Pull refresh token from cookie if not in request data
        if refresh_cookie_name in request.COOKIES and 'refresh' not in request.data:
            # We must make a mutable copy of request.data to inject the token
            mutable_data = request.data.copy()
            mutable_data['refresh'] = request.COOKIES[refresh_cookie_name]
            request._full_data = mutable_data
            
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == status.HTTP_200_OK:
            access_token = response.data.get('access')
            refresh_token = response.data.get('refresh') # Might be absent if not rotated
            
            response.set_cookie(
                key=cookie_settings.get('AUTH_COOKIE', 'access_token'),
                value=access_token,
                max_age=cookie_settings.get('ACCESS_TOKEN_LIFETIME').total_seconds() if cookie_settings.get('ACCESS_TOKEN_LIFETIME') else 3600,
                secure=settings.SESSION_COOKIE_SECURE,
                httponly=True,
                samesite=cookie_settings.get('AUTH_COOKIE_SAMESITE', 'Lax'),
            )
            if refresh_token:
                response.set_cookie(
                    key=cookie_settings.get('REFRESH_COOKIE', 'refresh_token'),
                    value=refresh_token,
                    max_age=cookie_settings.get('REFRESH_TOKEN_LIFETIME').total_seconds() if cookie_settings.get('REFRESH_TOKEN_LIFETIME') else 86400,
                    secure=settings.SESSION_COOKIE_SECURE,
                    httponly=True,
                    samesite=cookie_settings.get('AUTH_COOKIE_SAMESITE', 'Lax'),
                )
            
            # Remove tokens from JSON response body to enforce HttpOnly cookie usage
            if 'access' in response.data:
                del response.data['access']
            if 'refresh' in response.data:
                del response.data['refresh']
            response.data['detail'] = "Token muvaffaqiyatli yangilandi."
            
        return response


class LogoutView(TokenBlacklistView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    def post(self, request, *args, **kwargs):
        cookie_settings = getattr(settings, 'SIMPLE_JWT', {})
        refresh_cookie_name = cookie_settings.get('REFRESH_COOKIE', 'refresh_token')
        
        # Inject refresh token from cookie if not provided
        if refresh_cookie_name in request.COOKIES and 'refresh' not in request.data:
            mutable_data = request.data.copy()
            mutable_data['refresh'] = request.COOKIES[refresh_cookie_name]
            request._full_data = mutable_data

        try:
            response = super().post(request, *args, **kwargs)
        except Exception:
            # Even if blacklist fails (e.g. token expired), we still want to clear cookies
            response = Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)

        response.delete_cookie(cookie_settings.get('AUTH_COOKIE', 'access_token'))
        response.delete_cookie(refresh_cookie_name)
        return response
