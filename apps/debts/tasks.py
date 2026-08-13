from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from apps.debts.models import Debt
import logging

logger = logging.getLogger(__name__)

@shared_task
def check_upcoming_debt_payments():
    """
    Checks for debts that have a payment due within the next 3 days
    and triggers a notification (e.g., email or Telegram).
    """
    logger.info("Starting check_upcoming_debt_payments task...")
    
    today = timezone.now().date()
    target_date = today + timedelta(days=3)
    
    # In a full implementation, you'd filter by due dates.
    # Since Debt now uses amortization and has monthly due dates, 
    # we might need to calculate if a payment is due based on the start date
    # or a specific `next_due_date` field.
    # For MVP, assuming we can find debts that are active.
    
    active_debts = Debt.objects.filter(status='active')
    
    notifications_sent = 0
    for debt in active_debts:
        # Example logic: check if today is 3 days before the monthly payment day
        # In a real app, you might store `next_due_date` explicitly on the Debt model.
        if debt.start_date:
            payment_day = debt.start_date.day
            
            # Simple check if the target_date day matches the payment day
            if target_date.day == payment_day:
                user = debt.user
                
                # Send email (using Django's send_mail or a custom notification service)
                try:
                    # from django.core.mail import send_mail
                    # send_mail(
                    #     subject='Upcoming Debt Payment Reminder',
                    #     message=f'Your payment for {debt.name} is due in 3 days.',
                    #     from_email='noreply@hisob.uz',
                    #     recipient_list=[user.email],
                    # )
                    logger.info(f"Notification sent to {user.email} for debt {debt.name}")
                    notifications_sent += 1
                except Exception as e:
                    logger.error(f"Failed to send notification for debt {debt.id}: {e}")
                    
    logger.info(f"Finished check_upcoming_debt_payments task. Sent {notifications_sent} notifications.")
    return notifications_sent
