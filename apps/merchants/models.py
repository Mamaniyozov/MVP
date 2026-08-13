from django.contrib.auth.models import User
from django.db import models
from django.db.models import Sum
from django.utils import timezone
from datetime import timedelta


class Merchant(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="merchants")
    name = models.CharField(max_length=100)
    category_name = models.CharField(max_length=50, null=True, blank=True)
    logo_url = models.URLField(null=True, blank=True)
    total_spent = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    transaction_count = models.IntegerField(default=0)
    last_transaction_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-total_spent"]
        constraints = [
            models.UniqueConstraint(fields=["user", "name"], name="unique_merchant_per_user")
        ]

    def __str__(self):
        return self.name

    def get_spending_trend(self, months=6):
        """Oxirgi N oylik xarajatlar trendi"""
        cutoff = timezone.now().date() - timedelta(days=30 * months)
        trends = (
            self.transactions.filter(type="expense", date__gte=cutoff)
            .values("date__year", "date__month")
            .annotate(total=Sum("amount"))
            .order_by("date__year", "date__month")
        )
        return list(trends)
