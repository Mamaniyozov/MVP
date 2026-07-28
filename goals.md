# Goals

_Audit date: 2026-07-25, last updated 2026-07-28. Based on repo structure, README.md, git log, config files, and direct source inspection of `apps/`, `mobile/lib/`, and `web/src/`._

## Current State

- **Personal finance MVP** (B2C): Django REST Framework backend + Flutter mobile client + Next.js web client. Backend is feature-complete for the planned MVP scope; mobile client now covers transactions, goals, and the two core analytics screens (see "What Has Been Done"); a full Next.js web frontend was also added (commit `831dfda`) with routes for dashboard/transactions/goals/categories/cards/analytics — **not yet audited in this file**, `needs review` on its scope/parity with the mobile app and backend.
- Backend apps: `users`, `categories`, `cards`, `transactions`, `goals`, `analytics` — all wired into `config/urls.py` under `/api/v1/`, JWT-authenticated (`djangorestframework-simplejwt`), documented via `drf-spectacular` (Swagger UI at `/api/schema/swagger-ui/`).
- Mobile app (`mobile/`, Flutter, Riverpod + go_router + Dio): `auth` (login/register), `dashboard`, `transactions` (list + add), `goals` (list with progress bars + inline add-progress dialog, add-goal screen), and `analytics` (category-breakdown pie chart, monthly report with month-over-month comparison) all exist under `lib/features/`. `categories` and `cards` still exist only as read-only data layers (no management screens yet).
- Git history is now structured: recent commits include `9b6ce79` (goals mobile feature), `6b328d8` (category-breakdown chart), `a320fec` (monthly report screen), on top of `831dfda` (Next.js web frontend) and `fe56335`/`c18c0a3` (transactions feature, backend validator fixes). Each mobile feature was committed separately, scoped to just that feature's files.
- No CI/CD configuration exists (`.github/` absent, no other CI config found) — `needs review` on whether any external CI is configured elsewhere.
- `mobile/test/` contains only the unmodified default Flutter counter-app smoke test (`widget_test.dart`) — effectively zero real test coverage on the mobile side. Backend (`apps/*/tests.py`) has real test coverage including explicit cross-user data-isolation tests.
- Stray untracked artifacts observed in working tree during recent sessions (`mobile/_cardId`, an empty root-level `entries` file, screenshot PNGs, `.playwright-mcp/`) — likely accidental, `needs review` for cleanup; none have been added to git.

## What Has Been Done

**Backend (Django/DRF) — essentially complete for MVP scope:**
- `users`: register/login/JWT-refresh endpoints; registering a user auto-creates a `UserProfile` and a default set of Uzbek-language expense/income categories via a `post_save` signal (`apps/users/services.py`).
- `categories`, `cards`: full CRUD, user-scoped querysets, default (global) categories supported alongside user-owned ones.
- `transactions`: full CRUD with pagination (`page_size=20`), filtering (`category`, `type`, `card`, `date_from`, `date_to`), ordering; cross-user leak tests present.
- `goals`: CRUD + dedicated "add progress" action with its own validated serializer.
- `analytics`: three endpoints — `category-breakdown`, `monthly-trend`, `monthly-report` — implemented and user-scoped.
- Security/data-isolation audit passed: `IsAuthenticated` enforced everywhere except intentionally-public register/login; every `get_queryset` filters by `request.user`.
- Two critical bugs found and fixed this session: (1) missing `MinValueValidator` on `Transaction.amount` and `Goal.target_amount`/`current_amount` — migrations `apps/transactions/migrations/0002_...` and `apps/goals/migrations/0002_...` created and applied; (2) `.env.example` had wrong variable names (`DEBUG`/`SECRET_KEY`/`ALLOWED_HOSTS`/`POSTGRES_HOST` instead of the `DJANGO_*`/`DB_HOST` names `config/settings.py` actually reads) — corrected.

**Mobile (Flutter) — auth, transactions, goals, and analytics:**
- Auth: register/login screens, JWT token storage (`flutter_secure_storage`), auto-refresh-on-401 Dio interceptor, force-logout event bus, Uzbek-localized error messages, defensive catch-all error handling.
- Transactions: domain model, paginated repository (list + create), transaction list screen (pull-to-refresh, empty/error states, income/expense color coding), add-transaction form (type toggle, amount, date picker, category dropdown filtered by type, optional card dropdown, note).
- **Goals** (`mobile/lib/features/goals/`, commit `9b6ce79`): domain model, repository (`list`/`create`/`add-progress`), list screen with progress-bar cards and an inline "add progress" dialog, add-goal screen (name, target amount, optional deadline). Mirrors the transactions feature's layer structure.
- **Analytics** (`mobile/lib/features/analytics/`, commits `6b328d8`, `a320fec`): category-breakdown pie chart screen (`fl_chart`, month/year navigation) and monthly report screen (income/expense/savings totals, % change vs. previous month, Uzbek insight text). Shared `uzMonthNames` constant extracted for both screens.
- Categories/Cards: read-only repositories + Riverpod providers (`allCategoriesProvider`, `categoriesByTypeProvider`, `cardsProvider`) — built specifically to support the transaction form's dropdowns, not as standalone management screens.
- Dashboard now has cards navigating to transactions, goals, category-breakdown, and monthly report.

## What Is Left

- **Categories management screen** — no mobile UI to create/edit/delete user categories (backend supports it fully; note `apps/categories/views.py` blocks editing/deleting global (`user=null`) and `is_default=True` categories — UI must respect that, e.g. disable edit/delete on those rows).
- **Cards management screen** — no mobile UI to create/edit/delete cards (backend supports it fully).
- **Monthly trend screen** (`analytics/monthly-trend/`, line/bar chart over N months) — backend endpoint exists and is implemented server-side but has no mobile screen yet; not explicitly in the original product-brief priority list but a natural analytics companion to category-breakdown and monthly-report.
- **Web frontend (`web/`)** — added by a separate, unaudited change (commit `831dfda`); has route folders mirroring every backend feature (dashboard/transactions/goals/categories/cards/analytics). `needs review`: has this been checked for parity/consistency with the backend contracts the mobile app uses, and does it have its own test coverage?
- **Offline-first architecture** — not started. No `sqflite`/`hive`/`drift`/`isar` dependency in `pubspec.yaml`; app is fully remote-API-dependent with no local persistence or sync layer.
- **Real mobile test coverage** — `mobile/test/` only has the default Flutter counter-app test; no widget/unit tests exist for auth, transactions, goals, analytics, or any other feature.
- **CI/CD** — `needs review`. No `.github/workflows` or equivalent found in-repo; unknown whether CI is configured externally.
- **Stray artifacts** — `mobile/_cardId`, a root-level empty `entries` file, and some screenshot PNGs/`.playwright-mcp/` seen untracked in recent sessions — should be reviewed and likely deleted; none are staged/committed.
- **`.claude-flow/`, `.swarm/` tooling state files** appear as modified/untracked in git status — `needs review` on whether these belong in version control at all (they look like local agent-tooling state, not project source).

## Next Goals

1. Build **Categories management screen** (create/edit/delete user categories, respecting the backend's protection on default/global categories) — closes a real gap since users currently cannot customize categories from the app.
2. Build **Cards management screen** (create/edit/delete cards) — same rationale.
3. Decide whether to build the **monthly-trend chart screen** (line/bar over N months) or defer it — backend is ready either way.
4. Add real mobile test coverage: start with the goals/analytics repositories and controllers added this session, plus the pre-existing transaction repository/controller, and at least one widget test per screen.
5. Audit the `web/` Next.js frontend (commit `831dfda`) against this same rubric — current state, what's done, what's left — since it currently has no equivalent write-up here.
6. Decide and document an offline-first strategy (or explicitly decide to defer it) — affects architecture choices for all remaining screens if adopted late.
7. Add minimal CI (lint + `flutter analyze` + `pytest` on push) — currently no automated verification exists.
8. Review and clean up the stray untracked artifacts and the `.claude-flow`/`.swarm` tracked-state files in git status.

## Where to Continue

**Immediate next file/module, in priority order:**

1. `mobile/lib/features/categories/presentation/` — extend the existing read-only data layer with create/edit/delete screens; reuse the `goals`/`transactions` feature structure (`domain/`, `data/`, `presentation/providers/`, `presentation/screens/`) and gate edit/delete UI on `is_default`/`user == null` per the backend's `perform_update`/`perform_destroy` checks.
2. `mobile/lib/features/cards/presentation/` — same pattern as categories.
3. `mobile/lib/features/analytics/` — optionally add a `monthly-trend` screen if prioritized ahead of categories/cards.
4. `mobile/test/` — backfill tests once each feature above stabilizes, rather than at the very end.
5. A short audit pass over `web/src/` to bring it into this file's tracking.

This order follows the dependency chain visible in the code: Categories and Cards management have zero mobile blockers (backend fully ready) and close the last major product-brief gaps on mobile. Monthly-trend, offline-first, and the web-frontend audit are lower urgency since the app is currently usable without them.
