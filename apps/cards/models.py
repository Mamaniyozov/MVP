from django.contrib.auth.models import User
from django.db import models


class Card(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="cards")
    name = models.CharField(max_length=50)
    last4 = models.CharField(max_length=4, blank=True)

    def __str__(self):
        return self.name
