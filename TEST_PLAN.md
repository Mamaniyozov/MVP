# Quality Assurance & Test Plan

## 1. Test Pyramid Strategy

- **Unit Tests (70%)**: Test individual model methods, utility functions, state managers, and data serializers.
- **Integration & API Tests (20%)**: Test end-to-end HTTP request/response flows, authentication, permissions, pagination, and middleware behavior.
- **Security & Regression Tests (10%)**: Test OWASP vulnerabilities (Idempotency isolation, SQL injection prevention, CORS, JWT rotation, Rate limiting).

---

## 2. Test Execution Commands

### Backend Pytest Suite
```bash
# Run all unit, integration, and security tests
pytest

# Run tests with coverage report
pytest --cov=apps --cov-report=term-missing
```

### Web Client Type Check & Build Validation
```bash
cd web
npx tsc --noEmit
npm run build
npm run lint
```

### Mobile Client Test Suite
```bash
cd mobile
flutter analyze
flutter test
```

---

## 3. Critical Test Matrix

| Component | Target Coverage | Current Status | Automated Test File |
|---|---|---|---|
| Auth & JWT Rotation | 100% | `PASSED` | `apps/users/tests.py` |
| Idempotency Middleware | 100% | `CRITICAL BUG FIXED` | `apps/users/tests.py` |
| Transaction CRUD & Budgets | 95% | `PASSED` | `apps/transactions/tests.py`, `apps/budgets/tests.py` |
| Analytics Query Optimization | 90% | `PASSED` | `apps/analytics/tests.py` |
| Mobile Offline Cache & Sync | 90% | `PASSED` | `mobile/test/core/storage/` |
| Web Routing & Error Boundaries | 85% | `PASSED` | Next.js build validation |
