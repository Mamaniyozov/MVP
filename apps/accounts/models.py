from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone
from datetime import timedelta


class Account(models.Model):
    ACCOUNT_TYPES = [
        ("checking", "Checking"),
        ("savings", "Savings"),
        ("credit_card", "Kredit karta"),
        ("cash", "Naqd pul"),
        ("digital_wallet", "Digital wallet (PayPal, Venmo, vb)"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="accounts")
    name = models.CharField(max_length=100)
    account_type = models.CharField(max_length=20, choices=ACCOUNT_TYPES)
    institution = models.CharField(max_length=100, blank=True)
    balance = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default="UZS")
    last_four = models.CharField(max_length=4, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-balance"]

    def __str__(self):
        return f"{self.name} ({self.get_account_type_display()})"

    def get_balance_history(self, days=30):
        """Oxirgi N kunlik balance o'zgarishi"""
        cutoff = timezone.now().date() - timedelta(days=days)
        transactions = self.transactions.filter(date__gte=cutoff).order_by("date")
        
        history = []
        running_balance = self.balance
        
        # We need to traverse backwards to reconstruct past balances
        for tx in reversed(transactions):
            if tx.type == "expense":
                running_balance += tx.amount
            else:
                running_balance -= tx.amount
                
            history.append({
                "date": tx.date,
                "balance": running_balance,
                "transaction_id": tx.id
            })
            
        return list(reversed(history))
