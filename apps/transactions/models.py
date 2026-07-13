from django.contrib.auth.models import User
from django.db import models

from apps.cards.models import Card
from apps.categories.models import Category


class Transaction(models.Model):
    TYPE_CHOICES = [
        ("income", "Daromad"),
        ("expense", "Xarajat"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="transactions")
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="transactions")
    card = models.ForeignKey(
        Card, null=True, blank=True, on_delete=models.SET_NULL, related_name="transactions"
    )
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    date = models.DateField()
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["user", "date"])]

    def __str__(self):
        return f"{self.type} {self.amount} ({self.date})"
