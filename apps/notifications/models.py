from django.contrib.auth.models import User
from django.db import models


class Notification(models.Model):
    TYPE_CHOICES = [
        ("system", "System"),
        ("transaction", "Transaction"),
        ("budget", "Budget"),
        ("goal", "Goal"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="system")
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.title}"


class UserDevice(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="devices")
    device_id = models.CharField(max_length=255, unique=True, help_text="Unique device identifier (e.g. UUID)")
    fcm_token = models.CharField(max_length=255, help_text="Firebase Cloud Messaging token")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - {self.device_id}"
