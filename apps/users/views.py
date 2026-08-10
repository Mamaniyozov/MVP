from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

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


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthAnonRateThrottle]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)
        return Response(
            {"access": str(refresh.access_token), "refresh": str(refresh)},
            status=status.HTTP_200_OK,
        )


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

        user = profile.user
        refresh = RefreshToken.for_user(user)
        return Response(
            {"access": str(refresh.access_token), "refresh": str(refresh)},
            status=status.HTTP_200_OK,
        )
