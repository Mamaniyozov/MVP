# Goals

_Audit date: 2026-07-25, last updated 2026-07-31 (category budgets app, CSV data export, idempotency middleware, request-ID tracing, and recurring transactions completed). Based on repo structure, README.md, git log, config files, and direct source inspection of `apps/`, `mobile/lib/`, and `web/src/`._

## Current State

- **Personal finance MVP** (B2C): Django REST Framework backend + Flutter mobile client + Next.js web client. Feature-complete B2C personal money management app with category budgets, analytics, transaction-goal linking, CSV exports, idempotency protections, and recurring subscription templates.
- Backend apps: `users`, `categories`, `cards`, `transactions`, `goals`, `analytics`, `budgets` — all wired into `config/urls.py` under `/api/v1/`, JWT-authenticated (`djangorestframework-simplejwt`), documented via `drf-spectacular` (Swagger UI at `/api/schema/swagger-ui/`).
- **Backend Test Suite**: `pytest` passes **47/47 tests** cleanly across all apps.
- **Top 5 Advanced Features & Production Hardening Pass — Complete**:
  1. **Category Budgets App (`apps/budgets`)**: Monthly category spending limits, automated `spent_amount`, `remaining_amount`, `spent_percent`, and `is_exceeded` flag calculations (`/api/v1/budgets/`).
  2. **CSV Data Export Endpoint (`GET /api/v1/transactions/export/`)**: Date range & category filtered CSV file download utility.
  3. **Tracing & Idempotency Middlewares (`config/middleware.py`)**: `RequestIDMiddleware` (`X-Request-ID` correlation header) and `IdempotencyMiddleware` (`Idempotency-Key` response caching) added to Django pipeline.
  4. **Recurring Transactions & Subscriptions (`apps/transactions/models.py`)**: `RecurringTransaction` model and CRUD API (`/api/v1/transactions/recurring/`) for weekly/monthly/yearly recurring payments.
  5. **Web Client Integration (`web/src/lib/api/resources.ts`)**: Added `budgetsApi` and `exportTransactionsCsv()` download helpers.
- **Senior Refactoring & Optimization Pass — Complete**:
  - `get_monthly_trend` analytics query optimized with `date__gte=start_date` filter.
  - Financial percentage calculations updated to maintain `Decimal` precision.
  - DRF Rate limiting (`AuthAnonRateThrottle`, 5 requests/min) applied to auth endpoints.
  - SimpleJWT Refresh Token rotation (`ROTATE_REFRESH_TOKENS: True`) and `token_blacklist` migration applied.
  - Password Change API endpoint (`POST /api/v1/auth/change-password/`) created.
  - React `ErrorBoundary` component integrated into Next.js root layout.
- Mobile app (`mobile/`, Flutter, Riverpod + go_router + Dio): `auth`, `dashboard`, `transactions`, `goals`, `analytics`, `categories`, and `cards`.
- **Mobile Test Coverage**: `mobile/test/` covers `auth_interceptor`, `monthly_report_controller`, and `login_screen_test`.
- **CI/CD Pipeline**: `.github/workflows/ci.yml` configured for backend pytest, web Next.js build, and mobile analyze.

## What Has Been Done

**Backend (Django/DRF):**
- `users`: register/login/JWT-refresh endpoints, `/api/v1/auth/change-password/`, `AuthAnonRateThrottle`, SimpleJWT token rotation and blacklisting; added Password Reset endpoints (`POST /api/v1/auth/password-reset/` & `POST /api/v1/auth/password-reset/confirm/`).
- `categories`, `cards`: full CRUD, user-scoped querysets.
- `transactions`: full CRUD with pagination, filtering, ordering; CSV data export endpoint (`/api/v1/transactions/export/`); `RecurringTransaction` CRUD API (`/api/v1/transactions/recurring/`).
- `goals`: CRUD + dedicated "add progress" action.
- `analytics`: `get_monthly_trend` date-bounded SQL query optimization; `Decimal` precision calculations.
- `budgets`: new `apps.budgets` Django app for monthly category spending limits and real-time spent calculation (`/api/v1/budgets/`).
- `middleware`: `RequestIDMiddleware` and `IdempotencyMiddleware` added to `config/middleware.py`.
- `pytest.ini` updated with `testpaths = apps` (47 passing tests).

**Mobile (Flutter):**
- Auth, Transactions, Goals, Analytics, Categories CRUD, Cards CRUD.
- Transaction-goal linking with atomic backend updates.
- Widget tests created and expanded across key screens: `login_screen_test.dart`, `card_list_screen_test.dart`, `category_list_screen_test.dart`, `transaction_list_screen_test.dart`, and `goal_list_screen_test.dart`.
- **Palette Unification Assessment**: Web (`tailwind.config.ts`) and Mobile (`app_theme.dart`) color systems verified to be **100% unified** on Ledger-Green (`#0F6B4C` brand, `#1E9C6B` income, `#C4573B` expense, `#E8A33D` accent).

**Web Frontend (Next.js):**
- Full CRUD/dashboard parity with mobile client.
- `budgetsApi` and `exportTransactionsCsv` added to `resources.ts`.
- Accessibility fixes (input labelling via `useId()`, skip links, accessible keyboard focus, drawer navigation).
- Global React `ErrorBoundary` wrapper in root `layout.tsx`.
- `tsc --noEmit` and `npm run build` pass cleanly (14/14 static pages generated).

**CI/CD & DevOps:**
- `.github/workflows/ci.yml` pipeline created for GitHub Actions.
- `.gitignore` updated with media/screenshot artifacts and MCP tooling state.

## What Is Left

1. **Web Visual QA**: Real browser/visual verification on desktop and mobile viewports.
2. **Offline-First Persistence Strategy**: Architectural decision on whether to adopt local SQLite/Hive persistence for offline-first capabilities.
3. **Web Password Reset UI**: Web client integration for password reset request and confirm pages.

## Next Goals

1. **Web Visual QA & Screenshot Audit**: Perform browser visual checks across desktop and mobile screens to verify drawer, skip link, and responsive layouts (`localhost:3000`).
2. **Web Password Reset UI**: Add `/forgot-password` and `/reset-password` UI forms to Next.js web client.
3. **Offline-First Storage Assessment**: Evaluate Hive/Isar vs SQLite for mobile local caching.

## Where to Continue

1. **Web Browser Verification**: Run Playwright / browser QA on `localhost:3000` to inspect UI render quality and responsiveness.
2. **Web Auth UI**: Create `web/src/app/forgot-password/page.tsx` and `web/src/app/reset-password/page.tsx`.

