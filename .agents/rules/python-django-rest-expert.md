# Python Django 5 & REST Framework Best Practices

Rule source: Agentpedia Codes (https://agentpedia.codes/rules/backend-frameworks/django-python-framework)

## Core Principles
1. **User Isolation**: Always scope QuerySets to the authenticated user (`filter(user=request.user)`).
2. **Database Performance**: Use `select_related()` for foreign keys and `prefetch_related()` for reverse relations. Utilize composite indexes `(user, date)` for high-cardinality queries.
3. **Idempotency & Middleware**: Protect non-idempotent endpoints (`POST`, `PUT`, `PATCH`) with JWT-aware `IdempotencyMiddleware`.
4. **JWT Security**: Enforce short-lived access tokens and refresh token rotation with blacklisting.
5. **OpenAPI Documentation**: Keep `drf-spectacular` schemas updated and decorated on API views.
