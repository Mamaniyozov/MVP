# Hisob Finance — Architecture Threat Model

## 1. System Overview

| Component | Technology | Role |
|-----------|-----------|------|
| Backend API | Django 6.0 + DRF + Gunicorn | Business logic, authentication, data access |
| Frontend | Next.js 15 (standalone) | Web UI, SSR |
| Mobile | Flutter | Cross-platform mobile client |
| Database | PostgreSQL 16 | Primary data store |
| Cache | Django default cache | Idempotency keys |
| Auth | SimpleJWT (access+refresh) | Token-based authentication |
| CI/CD | GitHub Actions | Build, test, security scans |

## 2. Trust Boundaries

```
[Internet] --> [Reverse Proxy / LB]
                  |
    +-------------+-------------+
    |                           |
[Next.js Web]          [Flutter Mobile]
    |                           |
    +-------------+-------------+
                  |
          [Django API (Gunicorn)]
                  |
          [PostgreSQL 16]
```

## 3. Threat Analysis (STRIDE)

### Spoofing
| Threat | Mitigation | Status |
|--------|------------|--------|
| Stolen JWT tokens | Short-lived access tokens (60 min), rotate refresh tokens, blacklist on rotation | ✅ Implemented |
| Brute-force login | AuthAnonRateThrottle (5/min) on auth endpoints | ✅ Implemented |
| Weak passwords | Django password validators (min length, common, numeric, similarity) | ✅ Implemented |

### Tampering
| Threat | Mitigation | Status |
|--------|------------|--------|
| CSV formula injection | sanitize_csv() strips leading =, +, -, @, \t, \r | ✅ Implemented |
| Concurrent balance manipulation | select_for_update pessimistic locking on Goal | ✅ Implemented |
| CSRF attacks | Django CsrfViewMiddleware enabled | ✅ Implemented |

### Repudiation
| Threat | Mitigation | Status |
|--------|------------|--------|
| Untracked admin access | AuditLogMiddleware logs admin/export access with user, IP, action | ✅ Implemented |
| Missing request correlation | RequestIDMiddleware adds X-Request-ID to every request | ✅ Implemented |

### Information Disclosure
| Threat | Mitigation | Status |
|--------|------------|--------|
| CORS misconfiguration | CORS_ALLOW_ALL_ORIGINS=False in production, explicit allowlist | ✅ Implemented |
| Sensitive headers | X-Frame-Options=DENY, SECURE_CONTENT_TYPE_NOSNIFF=True | ✅ Implemented |
| Error information leakage | DEBUG=False in production, Sentry captures errors server-side | ✅ Implemented |

### Denial of Service
| Threat | Mitigation | Status |
|--------|------------|--------|
| API abuse | DRF throttling: anon=30/min, user=300/min, auth=5/min | ✅ Implemented |
| Slow queries | select_related on queryset joins, filtered exports | ✅ Implemented |

### Elevation of Privilege
| Threat | Mitigation | Status |
|--------|------------|--------|
| Data isolation bypass | All querysets filtered by request.user | ✅ Implemented |
| Unauthorized API access | IsAuthenticated default permission | ✅ Implemented |

## 4. Residual Risks

| Risk | Severity | Notes |
|------|----------|-------|
| No WAF (Web Application Firewall) | Medium | Recommended for production behind CDN |
| No MFA (Multi-Factor Authentication) | Medium | Planned for future release |
| No field-level encryption for PII | Low | Financial amounts are not PII per se |

## 5. Compliance Mapping

| Standard | Coverage |
|----------|----------|
| OWASP ASVS 5.0 (L1) | Rate limiting, input validation, auth controls |
| OWASP Top 10 (2021) | A01-A10 addressed via security middleware/validation |
| STRIDE | Full threat model above |
