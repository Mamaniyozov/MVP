from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
import requests
import logging

logger = logging.getLogger(__name__)

@shared_task
def check_upcoming_debt_payments():
    """3 kun oldin eslatma (Email + Telegram)"""
    from apps.debts.models import Debt
    
    today = timezone.now().date()
    upcoming_date = today + timedelta(days=3)
    
    debts = Debt.objects.filter(
        due_date=upcoming_date,
        is_paid_off=False,
        user__notification_enabled=True
    )
    
    notifications_sent = 0
    for debt in debts:
        # Email logic would go here
        # send_debt_reminder_email(debt)
        
        # Telegram
        if debt.user.telegram_chat_id:
            send_telegram_reminder(debt)
            notifications_sent += 1
            
    logger.info(f"Finished check_upcoming_debt_payments task. Sent {notifications_sent} telegram notifications.")
    return notifications_sent

def send_telegram_reminder(debt):
    """Telegram orqali eslatma"""
    bot_token = getattr(settings, 'TELEGRAM_BOT_TOKEN', None)
    chat_id = debt.user.telegram_chat_id
    
    if not bot_token or not chat_id:
        return
        
    message = f"""
💳 **Qarz Eslatmasi**

📋 **{debt.name}**
💰 **Miqdor**: {debt.minimum_payment:,.0f} UZS
📅 **To'lov sanasi**: {debt.due_date.strftime('%d.%m.%Y')}
⚠️ **Qolgan kun**: 3 kun

To'lovni unutmang!
    """
    
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    data = {
        'chat_id': chat_id,
        'text': message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.post(url, json=data, timeout=10)
        response.raise_for_status()
    except Exception as e:
        logger.error(f"Telegram error: {e}")
