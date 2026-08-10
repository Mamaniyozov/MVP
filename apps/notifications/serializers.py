from rest_framework import serializers
from apps.notifications.models import Notification, UserDevice


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "message", "notification_type", "is_read", "created_at"]
        read_only_fields = fields


class UserDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDevice
        fields = ["device_id", "fcm_token"]

    def create(self, validated_data):
        user = self.context["request"].user
        device, created = UserDevice.objects.update_or_create(
            user=user,
            device_id=validated_data["device_id"],
            defaults={"fcm_token": validated_data["fcm_token"]}
        )
        return device
