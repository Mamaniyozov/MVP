"""
OTP generation, verification, and SMS sending logic.
MVP mode: SMS is logged to console instead of being sent to a real gateway.
"""
import logging
import random
import string

from django.core.cache import cache

logger = logging.getLogger("apps")

OTP_LENGTH = 6
OTP_TTL_SECONDS = 300  # 5 minutes
OTP_COOLDOWN_SECONDS = 60  # 1 minute between requests
MAX_VERIFY_ATTEMPTS = 3


def _otp_cache_key(phone_number: str) -> str:
    return f"otp_{phone_number}"


def _otp_cooldown_key(phone_number: str) -> str:
    return f"otp_cooldown_{phone_number}"


def _otp_attempts_key(phone_number: str) -> str:
    return f"otp_attempts_{phone_number}"


def generate_otp(phone_number: str) -> dict:
    """
    Generate a 6-digit OTP for the given phone number.
    Returns {"otp": "123456"} on success.
    Raises ValueError if cooldown is active.
    """
    cooldown_key = _otp_cooldown_key(phone_number)
    if cache.get(cooldown_key):
        raise ValueError("OTP allaqachon yuborilgan. 1 daqiqa kutib turing.")

    code = "".join(random.choices(string.digits, k=OTP_LENGTH))

    cache.set(_otp_cache_key(phone_number), code, timeout=OTP_TTL_SECONDS)
    cache.set(cooldown_key, True, timeout=OTP_COOLDOWN_SECONDS)
    cache.delete(_otp_attempts_key(phone_number))

    send_sms(phone_number, f"Hisob Finance: Sizning tasdiqlash kodingiz: {code}")

    return {"otp": code}


def verify_otp(phone_number: str, code: str) -> bool:
    """
    Verify the OTP code for the given phone number.
    Returns True on success.
    Raises ValueError on failure or too many attempts.
    """
    attempts_key = _otp_attempts_key(phone_number)
    attempts = cache.get(attempts_key, 0)

    if attempts >= MAX_VERIFY_ATTEMPTS:
        cache.delete(_otp_cache_key(phone_number))
        raise ValueError("Juda ko'p noto'g'ri urinish. Yangi OTP so'rang.")

    stored_code = cache.get(_otp_cache_key(phone_number))

    if stored_code is None:
        raise ValueError("OTP topilmadi yoki muddati o'tgan. Yangi kod so'rang.")

    if stored_code != code:
        cache.set(attempts_key, attempts + 1, timeout=OTP_TTL_SECONDS)
        raise ValueError("OTP kodi noto'g'ri.")

    # Success — clean up
    cache.delete(_otp_cache_key(phone_number))
    cache.delete(_otp_attempts_key(phone_number))
    cache.delete(_otp_cooldown_key(phone_number))

    return True


def send_sms(phone_number: str, message: str) -> None:
    """
    Send an SMS message. MVP mode: log to console.
    In production, replace with Eskiz.uz or Play Mobile API call.
    """
    logger.info("SMS [MVP-LOG] to=%s message=%s", phone_number, message)
