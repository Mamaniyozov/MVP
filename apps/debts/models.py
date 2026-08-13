from decimal import Decimal
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models


class Debt(models.Model):
    DEBT_TYPES = [
        ('credit_card', 'Kredit karta'),
        ('personal_loan', 'Shaxsiy kredit'),
        ('mortgage', 'Ipoteka'),
        ('student_loan', 'Ta\'lim krediti'),
        ('medical', 'Tibbiy qarzdorlik'),
        ('other', 'Boshqa'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="debts")
    name = models.CharField(max_length=100)
    debt_type = models.CharField(max_length=20, choices=DEBT_TYPES)
    total_amount = models.DecimalField(
        max_digits=15, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    balance = models.DecimalField(
        max_digits=15, decimal_places=2, validators=[MinValueValidator(Decimal("0.00"))]
    )
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2) # Yillik %
    minimum_payment = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.IntegerField(validators=[MinValueValidator(1)]) # Har oydagi sana (1-31)
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    is_paid = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} - {self.balance}"

    def get_payoff_schedule(self, extra_payment=0):
        """Qarz to'lash grafigini hisoblash"""
        monthly_interest = (self.interest_rate / Decimal('100')) / Decimal('12')
        current_balance = self.balance
        payment = self.minimum_payment + Decimal(str(extra_payment))
        schedule = []
        
        month = 0
        while current_balance > 0 and month < 360: # Max 30 yil
            month += 1
            interest_charge = current_balance * monthly_interest
            principal_payment = payment - interest_charge
            
            if principal_payment <= 0:
                # Agar to'lov foizni qoplamasa, cheksiz loopni oldini olamiz
                break
                
            if current_balance < payment:
                principal_payment = current_balance
                payment = current_balance + interest_charge
                
            current_balance -= principal_payment
            
            schedule.append({
                'month': month,
                'payment': round(payment, 2),
                'principal': round(principal_payment, 2),
                'interest': round(interest_charge, 2),
                'remaining_balance': round(max(Decimal('0'), current_balance), 2)
            })
            
        return schedule


class DebtPayment(models.Model):
    debt = models.ForeignKey(Debt, on_delete=models.CASCADE, related_name="payments")
    amount = models.DecimalField(
        max_digits=15, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    date = models.DateField()
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment {self.amount} for {self.debt.name}"

