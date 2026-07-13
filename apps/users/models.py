from django.contrib.auth.models import User
from django.db import models


class UserProfile(models.Model):
    PLAN_CHOICES = [
        ("free", "Free"),
        ("premium", "Premium"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    currency = models.CharField(max_length=3, default="UZS")
    plan = models.CharField(max_length=10, choices=PLAN_CHOICES, default="free")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} profile"
