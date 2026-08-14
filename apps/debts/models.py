from django.db import models
from django.core.validators import MinValueValidator
from dateutil.relativedelta import relativedelta
from decimal import Decimal

class Debt(models.Model):
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name='debts')
    
    name = models.CharField(max_length=100)  # "Auto Loan", "Credit Card"
    
    debt_type = models.CharField(max_length=20, choices=[
        ('credit_card', 'Kredit karta'),
        ('personal_loan', 'Shaxsiy kredit'),
        ('mortgage', 'Mortgage'),
        ('student_loan', 'Ta\'lim krediti'),
        ('medical', 'Tibbiy qarzdorlik'),
        ('other', 'Boshqa'),
    ])
    
    # Boshlang'ich qarz
    original_amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    # Joriy qarz (payments bilan kamayadi)
    current_balance = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    interest_rate = models.DecimalField(
        max_digits=5, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )  # Yillik %
    
    minimum_payment = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    due_date = models.DateField()  # Har oy to'lov sanasi
    start_date = models.DateField()
    
    # Auto-calculated
    end_date = models.DateField(null=True, blank=True)  # Rejalashtirilgan tugash
    is_paid_off = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['user', 'due_date']),
            models.Index(fields=['user', 'is_paid_off']),
        ]
    
    def save(self, *args, **kwargs):
        # Payoff date hisoblash
        if not self.end_date and self.minimum_payment > 0:
            schedule = self.get_payoff_schedule()
            if schedule:
                self.end_date = schedule[-1]['date']
        
        # Paid off status
        self.is_paid_off = self.current_balance <= 0
        
        super().save(*args, **kwargs)
    
    def get_payoff_schedule(self):
        """Amortizatsiya grafigi"""
        monthly_interest = self.interest_rate / Decimal('12') / Decimal('100')
        balance = self.current_balance
        schedule = []
        
        current_date = self.due_date
        month = 0
        
        while balance > 0 and month < 360:  # Max 30 years
            month += 1
            interest_payment = balance * monthly_interest
            principal_payment = self.minimum_payment - interest_payment
            
            # Oxirgi to'lov
            if principal_payment > balance:
                principal_payment = balance
                total_payment = principal_payment + interest_payment
                balance = Decimal('0')
            else:
                total_payment = self.minimum_payment
                balance -= principal_payment
            
            schedule.append({
                'month': month,
                'date': current_date,
                'payment': round(total_payment, 2),
                'principal': round(principal_payment, 2),
                'interest': round(interest_payment, 2),
                'remaining_balance': round(max(Decimal('0'), balance), 2)
            })
            
            current_date += relativedelta(months=1)
        
        return schedule
    
    def get_total_interest_paid(self):
        """Jami to'langan foiz"""
        payments = self.payments.aggregate(
            total=models.Sum('interest_amount')
        )['total'] or Decimal('0')
        return payments
    
    def get_progress(self):
        """Qarz to'lash progressi"""
        paid = self.original_amount - self.current_balance
        percentage = (paid / self.original_amount * 100) if self.original_amount > 0 else Decimal('0')
        
        return {
            'original': self.original_amount,
            'current': self.current_balance,
            'paid': paid,
            'percentage': round(percentage, 2),
            'remaining_payments': len(self.get_payoff_schedule()),
        }

class DebtPayment(models.Model):
    """Haqiqiy qarz to'lovlari"""
    debt = models.ForeignKey(
        Debt, 
        on_delete=models.CASCADE,
        related_name='payments'
    )
    
    amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    # Split between principal and interest
    principal_amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    interest_amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))]
    )
    
    payment_date = models.DateField()
    notes = models.TextField(blank=True)
    is_late = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        # Validation: principal + interest = amount
        if self.principal_amount + self.interest_amount != self.amount:
            raise ValueError("Principal + Interest must equal total amount")
        
        super().save(*args, **kwargs)
        
        # Debt balance yangilash
        self.debt.current_balance -= self.principal_amount
        self.debt.save()
    
    def delete(self, *args, **kwargs):
        # Debt balance tiklash (delete oldin)
        self.debt.current_balance += self.principal_amount
        self.debt.save()
        super().delete(*args, **kwargs)
