from decimal import Decimal
from django.contrib.auth.models import User
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone

from apps.categories.models import Category
from apps.transactions.models import Transaction

class Budget(models.Model):
    PERIOD_CHOICES = [
        ("daily", "Kunlik"),
        ("weekly", "Haftalik"),
        ("monthly", "Oylik"),
        ("yearly", "Yillik"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="budgets")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name="budgets")
    amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    period = models.CharField(max_length=20, choices=PERIOD_CHOICES, default="monthly")
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    is_rollover = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "category", "period", "start_date"],
                name="unique_user_category_period_start_budget",
            )
        ]

    def __str__(self):
        return f"{self.user.email} - {self.category.name} ({self.period}): {self.amount}"

    def get_progress(self):
        """Byudjet bajarilish foizi"""
        qs = Transaction.objects.filter(
            user=self.user,
            category=self.category,
            type='expense',
            date__gte=self.start_date
        )
        if self.end_date:
            qs = qs.filter(date__lte=self.end_date)
        else:
            qs = qs.filter(date__lte=timezone.now().date())
            
        spent = qs.aggregate(total=models.Sum('amount'))['total'] or Decimal('0.00')
        
        return {
            'spent': spent,
            'budget': self.amount,
            'percentage': round((spent / self.amount * 100), 2) if self.amount > 0 else 0,
            'remaining': self.amount - spent
        }
