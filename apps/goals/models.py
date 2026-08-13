from decimal import Decimal
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models

class Goal(models.Model):
    PRIORITY_CHOICES = [
        (1, 'Low'),
        (2, 'Medium'),
        (3, 'High'),
    ]
    
    FREQUENCY_CHOICES = [
        ('weekly', 'Haftalik'),
        ('monthly', 'Oylik'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="goals")
    name = models.CharField(max_length=100)
    target_amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    current_amount = models.DecimalField(
        max_digits=14,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
    )
    deadline = models.DateField(null=True, blank=True)
    
    priority = models.IntegerField(default=2, choices=PRIORITY_CHOICES)
    auto_save = models.BooleanField(default=False)
    auto_save_amount = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(Decimal("0.01"))]
    )
    auto_save_frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    def calculate_months_to_goal(self, monthly_contribution=None):
        """Maqsadga yetish uchun kerakli oylar"""
        contrib = monthly_contribution or (self.auto_save_amount if self.auto_save_frequency == 'monthly' else None)
        if not contrib or contrib <= 0:
            return None
            
        remaining = self.target_amount - self.current_amount
        if remaining <= 0:
            return 0
            
        return float(remaining / contrib)
