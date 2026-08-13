from django.contrib.auth.models import User
from django.db import models


class FinancialReport(models.Model):
    REPORT_TYPES = [
        ('monthly_summary', 'Oylik Xulosa'),
        ('annual_summary', 'Yillik Xulosa'),
        ('category_analysis', 'Kategoriya Tahlili'),
        ('investment_performance', 'Investitsiya Natijasi'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reports")
    report_type = models.CharField(max_length=50, choices=REPORT_TYPES)
    period_start = models.DateField()
    period_end = models.DateField()
    data = models.JSONField(default=dict) # Tahlil natijalari (masalan, jami daromad, xarajat) JSON formatida
    is_generated = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    file_attachment = models.FileField(upload_to='reports/', null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_report_type_display()} ({self.period_start} - {self.period_end})"

