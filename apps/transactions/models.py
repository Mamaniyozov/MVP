from decimal import Decimal

from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models

from apps.accounts.models import Account
from apps.categories.models import Category
from apps.goals.models import Goal
from apps.merchants.models import Merchant
from apps.tags.models import Tag


class Transaction(models.Model):
    TYPE_CHOICES = [
        ("income", "Daromad"),
        ("expense", "Xarajat"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="transactions")
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="transactions")
    account = models.ForeignKey(
        Account, null=True, blank=True, on_delete=models.SET_NULL, related_name="transactions"
    )
    merchant = models.ForeignKey(
        Merchant, null=True, blank=True, on_delete=models.SET_NULL, related_name="transactions"
    )
    goal = models.ForeignKey(
        Goal, null=True, blank=True, on_delete=models.SET_NULL, related_name="transactions"
    )
    tags = models.ManyToManyField(Tag, blank=True, related_name="transactions")
    amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    date = models.DateField(db_index=True)
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "date"], name="txn_user_date_idx"),
            models.Index(fields=["user", "category", "date"], name="txn_user_cat_date_idx"),
        ]

    def __str__(self):
        return f"{self.type} {self.amount} ({self.date})"


class TransactionSplit(models.Model):
    transaction = models.ForeignKey(Transaction, on_delete=models.CASCADE, related_name="splits")
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.transaction.id} - {self.category.name}: {self.amount}"


class RecurringTransaction(models.Model):
    FREQUENCY_CHOICES = [
        ("daily", "Kunlik"),
        ("weekly", "Haftalik"),
        ("biweekly", "Har 2 hafta"),
        ("monthly", "Oylik"),
        ("quarterly", "Choraklik"),
        ("yearly", "Yillik"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="recurring_transactions")
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="recurring_transactions")
    account = models.ForeignKey(
        Account, null=True, blank=True, on_delete=models.SET_NULL, related_name="recurring_transactions"
    )
    amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    type = models.CharField(max_length=10, choices=Transaction.TYPE_CHOICES)
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, default="monthly")
    next_date = models.DateField(db_index=True)
    end_date = models.DateField(null=True, blank=True)
    note = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    auto_create = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "is_active", "next_date"], name="rec_txn_user_act_next_idx"),
        ]

    def __str__(self):
        return f"Recurring {self.type} {self.amount} ({self.frequency})"
