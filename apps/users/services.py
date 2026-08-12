import random
import logging
from django.core.cache import cache
from apps.categories.models import Category
from apps.users.models import UserProfile

logger = logging.getLogger("apps")

DEFAULT_EXPENSE_CATEGORIES = [
    ("Oziq-ovqat", "utensils"),
    ("Transport", "car"),
    ("Kommunal to'lovlar", "receipt"),
    ("Ko'ngilochar", "smile"),
    ("To'y/marosim", "gift"),
    ("Qarindoshlarga yordam", "heart"),
    ("Sog'liq", "activity"),
    ("Ta'lim", "book"),
    ("Boshqa", "more-horizontal"),
]

DEFAULT_INCOME_CATEGORIES = [
    ("Maosh", "briefcase"),
    ("Boshqa daromad", "plus-circle"),
]


def create_user_profile(user):
    UserProfile.objects.get_or_create(user=user)


def create_default_categories(user):
    categories = [
        Category(user=user, name=name, type="expense", icon=icon, is_default=True)
        for name, icon in DEFAULT_EXPENSE_CATEGORIES
    ] + [
        Category(user=user, name=name, type="income", icon=icon, is_default=True)
        for name, icon in DEFAULT_INCOME_CATEGORIES
    ]
    Category.objects.bulk_create(categories)


class SMSGatewayService:
    """
    Mock SMS Gateway Service for sending OTPs.
    In a real-world scenario, this would integrate with Eskiz or Twilio.
    """
    
    @staticmethod
    def send_otp(phone_number: str, otp: str) -> bool:
        logger.info(f"Sending OTP {otp} to {phone_number}")
        print(f"[SMS Gateway Mock] Sent OTP {otp} to {phone_number}")
        return True

    @staticmethod
    def generate_otp() -> str:
        return str(random.randint(100000, 999999))
    
    @classmethod
    def create_and_send_otp(cls, phone_number: str) -> bool:
        otp = cls.generate_otp()
        cache_key = f"otp_{phone_number}"
        
        cache.set(cache_key, otp, timeout=300)
        
        return cls.send_otp(phone_number, otp)

    @staticmethod
    def verify_otp(phone_number: str, otp: str) -> bool:
        cache_key = f"otp_{phone_number}"
        cached_otp = cache.get(cache_key)
        
        if cached_otp and cached_otp == otp:
            cache.delete(cache_key)
            return True
        return False
