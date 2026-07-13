from django.contrib.auth.models import User
from django.db import models


class Category(models.Model):
    TYPE_CHOICES = [
        ("income", "Daromad"),
        ("expense", "Xarajat"),
    ]

    user = models.ForeignKey(
        User, null=True, blank=True, on_delete=models.CASCADE, related_name="categories"
    )
    name = models.CharField(max_length=50)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    icon = models.CharField(max_length=30, blank=True)
    is_default = models.BooleanField(default=False)

    def __str__(self):
        return self.name
