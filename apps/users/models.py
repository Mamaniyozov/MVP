import re

from django.contrib.auth.models import User
from django.core.validators import RegexValidator
from django.db import models

PHONE_REGEX = RegexValidator(
    regex=r"^\+998\d{9}$",
    message="Telefon raqami +998XXXXXXXXX formatida bo'lishi kerak.",
)


class UserProfile(models.Model):
    PLAN_CHOICES = [
        ("free", "Free"),
        ("premium", "Premium"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    currency = models.CharField(max_length=3, default="UZS")
    plan = models.CharField(max_length=10, choices=PLAN_CHOICES, default="free")
    phone_number = models.CharField(
        max_length=13, validators=[PHONE_REGEX], unique=True, blank=True, null=True
    )
    is_phone_verified = models.BooleanField(default=False)
    telegram_chat_id = models.CharField(max_length=100, null=True, blank=True)
    notification_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} profile"

