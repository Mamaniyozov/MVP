from decimal import Decimal
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models


class InvestmentAccount(models.Model):
    ACCOUNT_TYPES = [
        ('stock', 'Aksiya'),
        ('crypto', 'Kriptovalyuta'),
        ('bond', 'Obligatsiya'),
        ('mutual_fund', 'Mutual Fund'),
        ('etf', 'ETF'),
        ('other', 'Boshqa')
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="investment_accounts")
    name = models.CharField(max_length=100)
    account_type = models.CharField(max_length=20, choices=ACCOUNT_TYPES)
    currency = models.CharField(max_length=3, default='USD')
    current_balance = models.DecimalField(
        max_digits=15, decimal_places=2, default=0,
        validators=[MinValueValidator(Decimal("0.00"))]
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.get_account_type_display()})"


class InvestmentHolding(models.Model):
    account = models.ForeignKey(InvestmentAccount, on_delete=models.CASCADE, related_name="holdings")
    symbol = models.CharField(max_length=20)
    name = models.CharField(max_length=100)
    quantity = models.DecimalField(max_digits=15, decimal_places=8, default=0)
    average_buy_price = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    current_price = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["account", "symbol"], name="unique_holding_per_account")
        ]

    def __str__(self):
        return f"{self.symbol} in {self.account.name}"

    @property
    def current_value(self):
        if self.current_price is None:
            return Decimal('0.00')
        return self.quantity * self.current_price

    @property
    def profit_loss(self):
        cost_basis = self.quantity * self.average_buy_price
        return self.current_value - cost_basis

    @property
    def profit_loss_percentage(self):
        cost_basis = self.quantity * self.average_buy_price
        if cost_basis > 0:
            return round(((self.current_value - cost_basis) / cost_basis * 100), 2)
        return Decimal('0.00')


class InvestmentTransaction(models.Model):
    TRANSACTION_TYPES = [
        ('buy', 'Sotib olish'),
        ('sell', 'Sotish'),
        ('dividend', 'Dividend/Foyda'),
        ('fee', 'Komissiya'),
    ]

    holding = models.ForeignKey(InvestmentHolding, on_delete=models.CASCADE, related_name="transactions")
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    quantity = models.DecimalField(max_digits=15, decimal_places=8, null=True, blank=True)
    price = models.DecimalField(max_digits=15, decimal_places=2)
    fees = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    date = models.DateTimeField()
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.get_transaction_type_display()} {self.quantity} {self.holding.symbol}"

