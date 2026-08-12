import qrcode
import base64
from io import BytesIO
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django_otp.plugins.otp_totp.models import TOTPDevice

from rest_framework.permissions import AllowAny, IsAuthenticated

class MFASetupView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        device, created = TOTPDevice.objects.get_or_create(user=user, name="default")
        
        # Generate QR code
        url = device.config_url
        qr = qrcode.make(url)
        buffered = BytesIO()
        qr.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
        
        return Response({
            "detail": "MFA setup QR code generated.",
            "qr_code": f"data:image/png;base64,{img_str}"
        }, status=status.HTTP_200_OK)


class MFAVerifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        token = request.data.get("token")
        temp_token = request.data.get("temp_token")
        
        if not token:
            return Response({"detail": "Token is required."}, status=status.HTTP_400_BAD_REQUEST)

        user = None
        if request.user and request.user.is_authenticated:
            user = request.user
        elif temp_token:
            from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
            signer = TimestampSigner()
            try:
                user_id = signer.unsign(temp_token, max_age=300) # 5 minutes expiry
                from django.contrib.auth import get_user_model
                user = get_user_model().objects.get(id=user_id)
            except SignatureExpired:
                return Response({"detail": "Token expired."}, status=status.HTTP_400_BAD_REQUEST)
            except (BadSignature, get_user_model().DoesNotExist):
                return Response({"detail": "Invalid temporary token."}, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({"detail": "Authentication required."}, status=status.HTTP_401_UNAUTHORIZED)

        device = TOTPDevice.objects.filter(user=user, name="default").first()
        
        if not device:
            return Response({"detail": "MFA not set up for this user."}, status=status.HTTP_400_BAD_REQUEST)
            
        if device.verify_token(token):
            if not device.confirmed:
                device.confirmed = True
                device.save()
            
            if temp_token:
                # Coming from login flow, issue JWT
                from rest_framework_simplejwt.tokens import RefreshToken
                refresh = RefreshToken.for_user(user)
                return Response(
                    {"access": str(refresh.access_token), "refresh": str(refresh)},
                    status=status.HTTP_200_OK,
                )

            return Response({"detail": "MFA token verified successfully."}, status=status.HTTP_200_OK)
            
        return Response({"detail": "Invalid MFA token."}, status=status.HTTP_400_BAD_REQUEST)
