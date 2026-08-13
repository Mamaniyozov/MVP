from django.db import models
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from decimal import Decimal

class Budget(models.Model):
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name="budgets")
    category = models.ForeignKey('categories.Category', on_delete=models.CASCADE, related_name="budgets")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    
    period = models.CharField(max_length=20, choices=[
        ('weekly', 'Haftalik'),
        ('monthly', 'Oylik'),
        ('yearly', 'Yillik'),
    ])
    
    # Yangi: Dinamik davr hisoblash
    start_date = models.DateField()  # Faqat boshlang'ich sana
    is_rollover_enabled = models.BooleanField(default=False)  # Rollover yoqilganmi?
    
    # Rollover tracking
    rollover_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    max_rollover_months = models.IntegerField(default=3)  # Maksimal 3 oy rollover
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'category', 'period', 'start_date'],
                name='unique_budget_per_category_period'
            )
        ]
    
    def get_current_period_range(self, reference_date=None):
        """Joriy davrni avtomatik hisoblash"""
        if reference_date is None:
            reference_date = timezone.now().date()
        
        if self.period == 'weekly':
            # Hafta boshi (Dushanba)
            start = reference_date - relativedelta(days=reference_date.weekday())
            end = start + relativedelta(days=6)
        
        elif self.period == 'monthly':
            # Oyning 1-sanasi
            start = reference_date.replace(day=1)
            end = (start + relativedelta(months=1)).replace(day=1) - relativedelta(days=1)
        
        elif self.period == 'yearly':
            # Yil boshi
            start = reference_date.replace(month=1, day=1)
            end = reference_date.replace(month=12, day=31)
        
        return start, end
    
    def get_progress(self, reference_date=None):
        """Byudjet progress + rollover hisoblash"""
        start, end = self.get_current_period_range(reference_date)
        
        # Joriy davr spending
        spent = self.user.transactions.filter(
            category=self.category,
            type='expense',
            date__range=[start, end]
        ).aggregate(total=models.Sum('amount'))['total'] or Decimal('0')
        
        # Rollover bilan birga umumiy byudjet
        effective_budget = self.amount + self.rollover_balance
        
        # Progress
        percentage = (spent / effective_budget * 100) if effective_budget > 0 else 0
        remaining = effective_budget - spent
        
        # Alert: 90% yetganda
        is_near_limit = percentage >= 90
        
        return {
            'period_start': start,
            'period_end': end,
            'spent': spent,
            'budget': self.amount,
            'rollover_balance': self.rollover_balance,
            'effective_budget': effective_budget,
            'percentage': round(percentage, 2),
            'remaining': remaining,
            'is_near_limit': is_near_limit,
        }
    
    def calculate_rollover(self, reference_date=None):
        """Keyingi oyga rollover hisoblash"""
        if not self.is_rollover_enabled:
            return Decimal('0')
        
        start, end = self.get_current_period_range(reference_date)
        
        # Joriy davr spending
        spent = self.user.transactions.filter(
            category=self.category,
            type='expense',
            date__range=[start, end]
        ).aggregate(total=models.Sum('amount'))['total'] or Decimal('0')
        
        # Rollover (ortiqcha mablag')
        unspent = self.amount - spent
        
        # Agar manfiy bo'lsa (over budget), rollover 0
        rollover = max(Decimal('0'), unspent)
        
        # Max rollover limit
        rollover = min(rollover, self.amount * self.max_rollover_months)
        
        return rollover
