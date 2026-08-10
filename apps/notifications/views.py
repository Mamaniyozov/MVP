from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404

from apps.notifications.models import Notification
from apps.notifications.serializers import NotificationSerializer, UserDeviceSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class NotificationMarkAsReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        notification = get_object_or_404(Notification, pk=pk, user=request.user)
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        return Response({"detail": "Xabar o'qilgan deb belgilandi."}, status=status.HTTP_200_OK)


class DeviceRegisterView(generics.CreateAPIView):
    serializer_class = UserDeviceSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        device = serializer.save()
        return Response(
            {"detail": "Qurilma ro'yxatdan o'tdi.", "device_id": device.device_id},
            status=status.HTTP_201_CREATED
        )
