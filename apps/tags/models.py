from django.contrib.auth.models import User
from django.db import models


class Tag(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="tags")
    name = models.CharField(max_length=50)
    color = models.CharField(max_length=7, default="#6B7280")
    icon = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "name"], name="unique_tag_per_user")
        ]

    def __str__(self):
        return self.name
