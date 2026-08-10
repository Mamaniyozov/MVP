# Security Audit Report (OWASP ASVS Standard)

## Executive Summary
This document provides a comprehensive security assessment of the Finance MVP application across backend API, frontend web client, mobile client, infrastructure, and authentication/authorization mechanisms.

---

## Security Vulnerability Matrix

| ID | Vulnerability | Severity | Impact | File / Location | Fix Strategy | Status |
|---|---|---|---|---|---|---|
| **SEC-01** | `IdempotencyMiddleware` Anonymous User Key Collision (Shared Cache Key across JWT Users) | `CRITICAL` | User A can view or overwrite User B's cached response if identical `Idempotency-Key` header is sent | [middleware.py:31](file:///d:/MVP/config/middleware.py#L31) | Extract JWT bearer token in middleware or generate user-scoped cache keys based on token payload hash | `FIXED` |
| **SEC-02** | Docker Containers Run as Root User | `HIGH` | Container escape exploit could lead to full host system compromise | [Dockerfile:1](file:///d:/MVP/Dockerfile#L1), [web/Dockerfile:1](file:///d:/MVP/web/Dockerfile#L1) | Add non-root `appuser` user and group in Dockerfile (`USER appuser`) | `OPEN` |
| **SEC-03** | Development Server (`runserver` & `npm run dev`) Used in Docker Containers | `HIGH` | Performance degradation, single-threaded bottlenecks, potential unhandled stack trace leaks | [Dockerfile:20](file:///d:/MVP/Dockerfile#L20), [docker-compose.yml:26](file:///d:/MVP/docker-compose.yml#L26) | Replace `runserver` with Gunicorn/WSGI server and Next.js standalone build | `OPEN` |
| **SEC-04** | Permissive CORS Fallback in Production Mode | `HIGH` | Cross-Origin Request Forgery / unauthorized cross-domain data access | [settings.py:155](file:///d:/MVP/config/settings.py#L155) | Enforce explicit `CORS_ALLOWED_ORIGINS` array and set `CORS_ALLOW_ALL_ORIGINS = False` | `OPEN` |
| **SEC-05** | Missing Security Response Headers (HSTS, CSP, Referrer Policy) | `MEDIUM` | Risk of MIME-sniffing, clickjacking, and referrer leakage in web clients | [settings.py:43](file:///d:/MVP/config/settings.py#L43) | Configure Django `SecurityMiddleware` flags (`SECURE_CONTENT_TYPE_NOSNIFF`, `X_FRAME_OPTIONS`, `SECURE_HSTS_SECONDS`) | `OPEN` |
| **SEC-06** | Missing Database Indexes on Frequently Filtered Foreign Keys (`user_id`, `date`) | `MEDIUM` | SQL Query performance degradation leading to DB DoS under load | [apps/transactions/models.py](file:///d:/MVP/apps/transactions/models.py) | Add `db_index=True` and composite `models.Index` on `(user, date)` | `OPEN` |
| **SEC-07** | Missing Centralized Security & Exception Logging | `LOW` | Inability to audit security breaches, unauthorized access attempts, or runtime errors | [settings.py:1](file:///d:/MVP/config/settings.py#L1) | Configure Python/Django `LOGGING` dict with JSON formatter and file/console handlers | `OPEN` |

---

## Detailed Exploit Scenarios & Verification

### SEC-01: Idempotency Key User Collision
- **Exploit Scenario**:
  Django's `AuthenticationMiddleware` does not populate `request.user` for SimpleJWT bearer tokens (DRF handles JWT authentication inside the view layer). When `IdempotencyMiddleware` executes before DRF authentication, `request.user.is_authenticated` returns `False`. The cache key generated is `idempotency_anon_<Idempotency-Key>`. If User A creates a transaction with `Idempotency-Key: TXN-100`, the response is cached under `idempotency_anon_TXN-100`. If User B subsequently sends any request with `Idempotency-Key: TXN-100`, `IdempotencyMiddleware` returns User A's cached response (`HIT-Idempotent`), exposing User A's transaction data to User B!
- **Verification Plan**:
  Write a pytest test case sending requests from two distinct JWT-authenticated users using the same `Idempotency-Key`. Verify that User B does NOT receive User A's response.
