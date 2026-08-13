from decimal import Decimal

from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models, transaction as db_transaction
from dateutil.relativedelta import relativedelta

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

    # Added to handle recurring transaction relations
    is_recurring = models.BooleanField(default=False)
    recurring_transaction = models.ForeignKey(
        'RecurringTransaction', null=True, blank=True, on_delete=models.SET_NULL, related_name="generated_transactions"
    )

    class Meta:
        indexes = [
            models.Index(fields=["user", "date"], name="txn_user_date_idx"),
            models.Index(fields=["user", "category", "date"], name="txn_user_cat_date_idx"),
        ]

    def __str__(self):
        return f"{self.type} {self.amount} ({self.date})"
        
    def save(self, *args, **kwargs):
        is_new = self.pk is None
        old_amount = Decimal('0')
        old_type = None
        old_account = None

        if not is_new:
            old_tx = Transaction.objects.get(pk=self.pk)
            old_amount = old_tx.amount
            old_type = old_tx.type
            old_account = old_tx.account
            
        super().save(*args, **kwargs)

        # Update Account Balance
        if self.account:
            # Revert old transaction if it was tied to an account
            if not is_new and old_account:
                if old_type == 'expense':
                    old_account.balance += old_amount
                elif old_type == 'income':
                    old_account.balance -= old_amount
                if old_account != self.account:
                    old_account.save()
            
            # Apply new transaction
            if self.type == 'expense':
                self.account.balance -= self.amount
            elif self.type == 'income':
                self.account.balance += self.amount
            self.account.save()
            
    def delete(self, *args, **kwargs):
        if self.account:
            if self.type == 'expense':
                self.account.balance += self.amount
            elif self.type == 'income':
                self.account.balance -= self.amount
            self.account.save()
        super().delete(*args, **kwargs)


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
    name = models.CharField(max_length=100, default="Recurring") # Adding name for the auto-generate note
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="recurring_transactions")
    account = models.ForeignKey(
        Account, null=True, blank=True, on_delete=models.SET_NULL, related_name="recurring_transactions"
    )
    amount = models.DecimalField(
        max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    type = models.CharField(max_length=10, choices=Transaction.TYPE_CHOICES)
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, default="monthly")
    next_payment_date = models.DateField(db_index=True)
    end_date = models.DateField(null=True, blank=True)
    note = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    auto_create = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "is_active", "next_payment_date"], name="rec_txn_user_act_next_idx"),
        ]

    def __str__(self):
        return f"Recurring {self.type} {self.amount} ({self.frequency})"

    def get_next_payment_date(self):
        """To'g'ri kalendar hisobi bilan keyingi sana"""
        if self.frequency == 'daily':
            return self.next_payment_date + relativedelta(days=1)
        elif self.frequency == 'weekly':
            return self.next_payment_date + relativedelta(weeks=1)
        elif self.frequency == 'biweekly':
            return self.next_payment_date + relativedelta(weeks=2)
        elif self.frequency == 'monthly':
            return self.next_payment_date + relativedelta(months=1)
        elif self.frequency == 'quarterly':
            return self.next_payment_date + relativedelta(months=3)
        elif self.frequency == 'yearly':
            return self.next_payment_date + relativedelta(years=1)
    
    def create_next_transaction(self):
        """Keyingi to'lovni yaratish"""
        with db_transaction.atomic():
            # Transaction yaratish
            Transaction.objects.create(
                user=self.user,
                account=self.account,
                category=self.category,
                amount=self.amount,
                type=self.type,
                date=self.next_payment_date,
                note=f"Auto: {self.name}",
                is_recurring=True,
                recurring_transaction=self
            )
            
            # Keyingi sanani yangilash
            self.next_payment_date = self.get_next_payment_date()
            
            # Agar end_date yetgan bo'lsa, deactivate
            if self.end_date and self.next_payment_date > self.end_date:
                self.is_active = False
            
            self.save()
