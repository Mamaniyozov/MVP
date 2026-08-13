from django.db import models
from django.core.validators import MinValueValidator
from decimal import Decimal

class InvestmentAccount(models.Model):
    """Investitsiya hisobi (masalan: Binance, Robinhood)"""
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name="investment_accounts")
    name = models.CharField(max_length=100)  # "Binance", "Robinhood"
    
    account_type = models.CharField(max_length=20, choices=[
        ('stock', 'Aksiya'),
        ('crypto', 'Kriptovalyuta'),
        ('bond', 'Obligatsiya'),
        ('mutual_fund', 'Mutual Fund'),
        ('etf', 'ETF'),
        ('other', 'Boshqa'),
    ])
    
    currency = models.CharField(max_length=3, default='USD')
    created_at = models.DateTimeField(auto_now_add=True)
    
    def get_total_value(self):
        """Jami portfolio qiymati"""
        holdings = self.holdings.filter(is_active=True)
        return sum((holding.current_value for holding in holdings), Decimal('0'))
    
    def get_total_profit_loss(self):
        """Jami profit/loss"""
        holdings = self.holdings.filter(is_active=True)
        return sum((holding.profit_loss for holding in holdings), Decimal('0'))

class InvestmentHolding(models.Model):
    """Joriy aktiv (masalan: AAPL 10 ta)"""
    account = models.ForeignKey(
        InvestmentAccount, 
        on_delete=models.CASCADE,
        related_name='holdings'
    )
    
    symbol = models.CharField(max_length=20)  # "AAPL", "BTC"
    name = models.CharField(max_length=100)  # "Apple Inc", "Bitcoin"
    
    # Jami miqdor (barcha transaction'lardan yig'indi)
    quantity = models.DecimalField(
        max_digits=15, 
        decimal_places=8,
        validators=[MinValueValidator(Decimal("0"))],
        default=Decimal("0")
    )
    
    # O'rtacha sotib olish narxi (weighted average)
    average_buy_price = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))],
        default=Decimal("0")
    )
    
    # Joriy bozor narxi (manual yoki API orqali yangilanadi)
    current_price = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        null=True,
        blank=True
    )
    
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['account', 'symbol'],
                name='unique_holding_per_account'
            )
        ]
    
    @property
    def cost_basis(self):
        """Jami sarmoya (quantity * average_buy_price)"""
        return self.quantity * self.average_buy_price
    
    @property
    def current_value(self):
        """Joriy qiymat"""
        if not self.current_price:
            return Decimal('0')
        return self.quantity * self.current_price
    
    @property
    def profit_loss(self):
        """Profit/Loss (absolute)"""
        return self.current_value - self.cost_basis
    
    @property
    def profit_loss_percentage(self):
        """Profit/Loss (percentage)"""
        if self.cost_basis == Decimal('0'):
            return Decimal('0')
        return round((self.profit_loss / self.cost_basis * 100), 2)
    
    def update_from_transactions(self):
        """Transaction'lardan holding'ni yangilash"""
        transactions = self.transactions.filter(is_cancelled=False)
        
        total_quantity = Decimal('0')
        total_cost = Decimal('0')
        
        for tx in transactions:
            if tx.transaction_type == 'buy':
                total_quantity += tx.quantity
                total_cost += tx.quantity * tx.price
            elif tx.transaction_type == 'sell':
                total_quantity -= tx.quantity
                # Cost basis kamayadi (proportional)
                avg_price = total_cost / total_quantity if total_quantity > 0 else Decimal('0')
                total_cost -= tx.quantity * avg_price
        
        self.quantity = total_quantity
        self.average_buy_price = total_cost / total_quantity if total_quantity > 0 else Decimal('0')
        self.is_active = total_quantity > 0
        self.save()

class InvestmentTransaction(models.Model):
    """Har bir oldi-sotdi operatsiyasi"""
    holding = models.ForeignKey(
        InvestmentHolding,
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    
    transaction_type = models.CharField(max_length=20, choices=[
        ('buy', 'Sotib olish'),
        ('sell', 'Sotish'),
        ('dividend', 'Dividend'),
        ('transfer_in', 'Kirish transfer'),
        ('transfer_out', 'Chiqish transfer'),
    ])
    
    quantity = models.DecimalField(
        max_digits=15, 
        decimal_places=8,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    price = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    total_amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        editable=False,
        default=Decimal("0")
    )
    
    transaction_date = models.DateField()
    notes = models.TextField(blank=True)
    is_cancelled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate total_amount
        if self.transaction_type in ['buy', 'sell']:
            self.total_amount = self.quantity * self.price
        elif self.transaction_type == 'dividend':
            self.total_amount = self.quantity  # Dividend - to'g'ridan-to'g'ri summa
        else:
            self.total_amount = Decimal('0')
        
        super().save(*args, **kwargs)
        
        # Holding'ni yangilash
        self.holding.update_from_transactions()
    
    def delete(self, *args, **kwargs):
        # Holding'ni yangilash (delete oldin)
        holding = self.holding
        super().delete(*args, **kwargs)
        holding.update_from_transactions()
