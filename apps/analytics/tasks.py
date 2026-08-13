import logging
from celery import shared_task
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from .models import FinancialReport

logger = logging.getLogger(__name__)

@shared_task
def generate_monthly_reports():
    """Har oy oxirida oylik hisobotlarni generatsiya qiluvchi Celery vazifasi"""
    today = timezone.now().date()
    # O'tgan oyning birinchi va oxirgi kunlari
    first_day = (today.replace(day=1) - relativedelta(months=1))
    last_day = today.replace(day=1) - relativedelta(days=1)
    
    logger.info(f"Generating monthly reports for {first_day} to {last_day}")
    
    # Aslida bu yerda barcha faol foydalanuvchilar uchun hisobot yaratiladi
    # User.objects.filter(is_active=True) ...
    # Masalan:
    # for user in users:
    #     report = FinancialReport.objects.create(
    #         user=user,
    #         report_type='monthly_summary',
    #         period_start=first_day,
    #         period_end=last_day,
    #         data={"income": 0, "expense": 0} # hisob-kitob qilinadi
    #     )
    #     report.is_generated = True
    #     report.save()
    
    return "Monthly reports generated successfully"

