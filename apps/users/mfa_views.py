import qrcode
import base64
from io import BytesIO
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django_otp.plugins.otp_totp.models import TOTPDevice

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
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")
        if not token:
            return Response({"detail": "Token is required."}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        device = TOTPDevice.objects.filter(user=user, name="default").first()
        
        if not device:
            return Response({"detail": "MFA not set up for this user."}, status=status.HTTP_400_BAD_REQUEST)
            
        if device.verify_token(token):
            if not device.confirmed:
                device.confirmed = True
                device.save()
            return Response({"detail": "MFA token verified successfully."}, status=status.HTTP_200_OK)
            
        return Response({"detail": "Invalid MFA token."}, status=status.HTTP_400_BAD_REQUEST)
