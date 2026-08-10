from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.users.views import (
    ChangePasswordView,
    LoginView,
    OTPRequestView,
    OTPVerifyView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    PhoneRegisterView,
    RegisterView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("refresh/", TokenRefreshView.as_view(), name="auth-refresh"),
    path("change-password/", ChangePasswordView.as_view(), name="auth-change-password"),
    path("password-reset/", PasswordResetRequestView.as_view(), name="auth-password-reset"),
    path("password-reset/confirm/", PasswordResetConfirmView.as_view(), name="auth-password-reset-confirm"),
    path("phone/register/", PhoneRegisterView.as_view(), name="auth-phone-register"),
    path("otp/request/", OTPRequestView.as_view(), name="auth-otp-request"),
    path("otp/verify/", OTPVerifyView.as_view(), name="auth-otp-verify"),
]
