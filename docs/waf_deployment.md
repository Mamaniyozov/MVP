# Web Application Firewall (WAF) Deployment Guide

Ushbu loyiha Cloudflare, AWS WAF yoki boshqa Reverse Proxy yechimlari orqasida ishlashga tayyorlangan. 

## 1. Django Sozlamalari (Settings)

Tizim WAF orqasida turganda, u haqiqiy mijoz (client) IP manzilini emas, balki WAF ning IP manzilini ko'radi. Buni oldini olish uchun `config/settings.py` faylida quyidagi sozlamalar yoqilgan:

```python
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True
USE_X_FORWARDED_PORT = True
```
Bu sozlamalar orqali Django X-Forwarded sarlavhalarini o'qib, requestlarni to'g'ri qayta ishlaydi.

## 2. Rate Limiting va IP manzil

Django Axes va Django Rest Framework throttling xizmatlari WAF orqasida to'g'ri ishlashi uchun proxy soni va qaysi headerni o'qish kerakligi belgilangan:

```python
AXES_PROXY_COUNT = 1
AXES_META_PRECEDENCE_ORDER = [
    'HTTP_X_FORWARDED_FOR',
    'REMOTE_ADDR',
]
```
Agarda Cloudflare yoki AWS WAF bir nechta proxy-qavatlardan tashkil topsa, `AXES_PROXY_COUNT` ni oshirishingiz mumkin.

## 3. Cloudflare uchun maxsus qoidalar

Agar siz Cloudflare ishlatsangiz, quyidagi WAF Rules (Qoidalar) ni yoqish tavsiya etiladi:
- **Rate Limiting**: `/api/v1/auth/login/` yo'nalishiga daqiqasiga 5 marta so'rov cheklovi (Limit).
- **Bot Fight Mode**: Botlarni bloklash uchun Cloudflare Dashboard'dan yoqilishi.
- **Managed Rules**: OWASP Core Ruleset'ni Cloudflare WAF orqali yoqish. 

## 4. AWS WAF uchun maxsus qoidalar

Agar loyiha AWS da Application Load Balancer (ALB) orqasida bo'lsa va AWS WAF biriktirilgan bo'lsa:
- **AWSManagedRulesCommonRuleSet** va **AWSManagedRulesKnownBadInputsRuleSet** kabi tayyor qoidalarni faollashtiring.
- SQL Injection va XSS hujumlarini oldini olish uchun ALB'ni bevosita shu WAF ACL ga bog'lang.
