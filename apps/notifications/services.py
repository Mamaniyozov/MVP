import logging

from django.core.mail import send_mail
from django.conf import settings

from apps.notifications.models import Notification

logger = logging.getLogger("apps")

def send_notification(user, title, message, notification_type="system", send_email=False, send_push=False):
    """
    Yagona entrypoint: In-app notification yaratadi va ixtiyoriy ravishda email/push yuboradi.
    """
    # 1. Create In-App Notification
    notification = Notification.objects.create(
        user=user,
        title=title,
        message=message,
        notification_type=notification_type
    )

    # 2. Email (MVP Mode - logged to console if real SMTP is not configured)
    if send_email and user.email:
        try:
            send_mail(
                subject=title,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL if hasattr(settings, 'DEFAULT_FROM_EMAIL') else 'noreply@hisob.finance',
                recipient_list=[user.email],
                fail_silently=True,
            )
            logger.info("Email yuborildi: to=%s, subject=%s", user.email, title)
        except Exception as e:
            logger.error("Email yuborishda xatolik: %s", str(e))

    # 3. Push Notification (FCM - MVP Mode just logs it)
    if send_push:
        devices = user.devices.all()
        for device in devices:
            logger.info("Push notification yuborilmoqda: device=%s, title=%s", device.fcm_token, title)
            # Production:
            # from firebase_admin import messaging
            # message = messaging.Message(
            #     notification=messaging.Notification(title=title, body=message),
            #     token=device.fcm_token,
            # )
            # messaging.send(message)

    return notification
