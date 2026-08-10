# Production Readiness Checklist

## 1. Security & Compliance
- [ ] `DJANGO_SECRET_KEY` set to a strong, randomly generated string in production environment.
- [ ] `DJANGO_DEBUG` explicitly set to `False`.
- [ ] `DJANGO_ALLOWED_HOSTS` restricted to exact production domain names.
- [ ] `CORS_ALLOW_ALL_ORIGINS` set to `False`; `CORS_ALLOWED_ORIGINS` set to web frontend domain.
- [ ] `IdempotencyMiddleware` verified to isolate user cache keys based on authenticated user ID / token payload.
- [ ] Containers configured to run under dedicated non-root users (`USER appuser`).
- [ ] SSL/TLS certificates configured on reverse proxy (Nginx / Cloudflare HSTS).

---

## 2. Infrastructure & Scalability
- [ ] Production WSGI server (Gunicorn with Gevent/Uvicorn workers) enabled for Django backend.
- [ ] Next.js standalone multi-stage production Docker build configured.
- [ ] Redis cache backend configured for Django session, rate limiting, and idempotency cache.
- [ ] Database connection pooling enabled (PostgreSQL `CONN_MAX_AGE`).
- [ ] Database indexes applied for transaction date, user_id, and category_id.

---

## 3. Operational Readiness
- [ ] Structured JSON logging configured.
- [ ] Health check endpoint (`/api/v1/health/`) responding with database connection status.
- [ ] Automated database backup policy verified and restore drill executed.
- [ ] All automated unit, integration, type check, and build commands passing cleanly.
