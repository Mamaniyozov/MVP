# Goals

_Audit date: 2026-07-25. Based on repo structure, README.md, mobile/README.md (default Flutter stub), git log, config files, and direct source inspection of `apps/` and `mobile/lib/`._

## Current State

- **Personal finance MVP** (B2C): Django REST Framework backend + Flutter mobile client. Backend is feature-complete for the planned MVP scope; mobile client has only the auth flow and a minimal transactions flow implemented.
- Backend apps: `users`, `categories`, `cards`, `transactions`, `goals`, `analytics` — all wired into `config/urls.py` under `/api/v1/`, JWT-authenticated (`djangorestframework-simplejwt`), documented via `drf-spectacular` (Swagger UI at `/api/schema/swagger-ui/`).
- Mobile app (`mobile/`, Flutter, Riverpod + go_router + Dio): only `auth` (login/register), a stub `dashboard`, and a newly-added `transactions` feature (list + add screen) exist under `lib/features/`. `categories` and `cards` exist as read-only data layers (no dedicated screens). `goals` and `analytics` have no mobile code at all.
- Git history is minimal and uninformative: 5 commits total (`Initial commit`, `new project`, `edit README.md`, `Revert "edit README.md"`, `fix bug`) — no structured commit history, no tags, no CHANGELOG.md. Recent substantial work (transactions feature, validator fixes, `.env.example` fix) is **uncommitted** in the working tree as of this audit.
- No CI/CD configuration exists (`.github/` absent, no other CI config found) — `needs review` on whether any external CI is configured elsewhere.
- `mobile/test/` contains only the unmodified default Flutter counter-app smoke test (`widget_test.dart`) — effectively zero real test coverage on the mobile side. Backend (`apps/*/tests.py`) has real test coverage including explicit cross-user data-isolation tests.
- A stray empty file `mobile/_cardId` exists in the working tree (untracked, 0 bytes) — likely an accidental artifact, needs cleanup review.

## What Has Been Done

**Backend (Django/DRF) — essentially complete for MVP scope:**
- `users`: register/login/JWT-refresh endpoints; registering a user auto-creates a `UserProfile` and a default set of Uzbek-language expense/income categories via a `post_save` signal (`apps/users/services.py`).
- `categories`, `cards`: full CRUD, user-scoped querysets, default (global) categories supported alongside user-owned ones.
- `transactions`: full CRUD with pagination (`page_size=20`), filtering (`category`, `type`, `card`, `date_from`, `date_to`), ordering; cross-user leak tests present.
- `goals`: CRUD + dedicated "add progress" action with its own validated serializer.
- `analytics`: three endpoints — `category-breakdown`, `monthly-trend`, `monthly-report` — implemented and user-scoped.
- Security/data-isolation audit passed: `IsAuthenticated` enforced everywhere except intentionally-public register/login; every `get_queryset` filters by `request.user`.
- Two critical bugs found and fixed this session: (1) missing `MinValueValidator` on `Transaction.amount` and `Goal.target_amount`/`current_amount` — migrations `apps/transactions/migrations/0002_...` and `apps/goals/migrations/0002_...` created and applied; (2) `.env.example` had wrong variable names (`DEBUG`/`SECRET_KEY`/`ALLOWED_HOSTS`/`POSTGRES_HOST` instead of the `DJANGO_*`/`DB_HOST` names `config/settings.py` actually reads) — corrected.

**Mobile (Flutter) — auth + transactions only:**
- Auth: register/login screens, JWT token storage (`flutter_secure_storage`), auto-refresh-on-401 Dio interceptor, force-logout event bus, Uzbek-localized error messages, defensive catch-all error handling (added this session to stop the UI from hanging on unexpected errors).
- Transactions: domain model, paginated repository (list + create), transaction list screen (pull-to-refresh, empty/error states, income/expense color coding), add-transaction form (type toggle, amount, date picker, category dropdown filtered by type, optional card dropdown, note).
- Categories/Cards: read-only repositories + Riverpod providers (`allCategoriesProvider`, `categoriesByTypeProvider`, `cardsProvider`) — built specifically to support the transaction form's dropdowns, not as standalone management screens.
- Dashboard now navigates to the transactions list (previously a dead-end welcome screen with only a logout button).
- `fl_chart` and `intl` are declared as dependencies but `fl_chart` is not yet used anywhere in the UI.

## What Is Left

- **Categories management screen** — no mobile UI to create/edit/delete user categories (backend supports it fully).
- **Cards management screen** — no mobile UI to create/edit/delete cards (backend supports it fully).
- **Goals (savings goals) feature** — entirely unbuilt on mobile: no domain model, repository, list/detail/add screens, or "add progress" UI, despite the backend endpoint being ready.
- **Analytics / charts (bar/line/pie)** — entirely unbuilt on mobile. `fl_chart` is installed but unused; no screen consumes `category-breakdown` or `monthly-trend` endpoints.
- **Monthly report screen** (month-over-month % comparison) — entirely unbuilt on mobile; backend endpoint (`monthly-report`) exists and is untested from the client side.
- **Offline-first architecture** — not started. No `sqflite`/`hive`/`drift`/`isar` dependency in `pubspec.yaml`; app is fully remote-API-dependent with no local persistence or sync layer.
- **Real mobile test coverage** — `mobile/test/` only has the default Flutter counter-app test; no widget/unit tests exist for auth, transactions, or any other feature.
- **CI/CD** — `needs review`. No `.github/workflows` or equivalent found in-repo; unknown whether CI is configured externally.
- **Uncommitted work** — the entire transactions feature, the two backend validator fixes, and the `.env.example` fix are currently uncommitted in the working tree. Risk: this work is not yet safely persisted to git history.
- **Stray artifact** — `mobile/_cardId` (empty, untracked) should be reviewed and likely deleted.
- **`.claude-flow/`, `.swarm/` tooling state files** appear as modified/untracked in git status — `needs review` on whether these belong in version control at all (they look like local agent-tooling state, not project source).

## Next Goals

1. Commit the current uncommitted work (transactions feature, validator migrations, `.env.example` fix) with clear, separated commits before starting new feature work.
2. Build the **Goals (savings goals)** mobile feature: domain model, repository, list screen, add/add-progress screens — backend is ready, no blockers.
3. Build the **category-breakdown chart screen** using `fl_chart` (already a dependency) against the existing `analytics/category-breakdown/` endpoint — bar or pie chart per the product brief.
4. Build the **Monthly report screen** against `analytics/monthly-report/`, showing current vs. previous month % change.
5. Build **Categories management screen** (create/edit/delete user categories) — closes a real gap since users currently cannot customize categories from the app.
6. Build **Cards management screen** (create/edit/delete cards) — same rationale.
7. Add real mobile test coverage: replace `widget_test.dart` with actual tests for the transaction repository/controller and at least one widget test per screen.
8. Decide and document an offline-first strategy (or explicitly decide to defer it) — affects architecture choices for all remaining screens if adopted late.
9. Add minimal CI (lint + `flutter analyze` + `pytest` on push) — currently no automated verification exists.
10. Review and clean up `mobile/_cardId` and the `.claude-flow`/`.swarm` tracked-state files in git status.

## Where to Continue

**Immediate next file/module, in priority order:**

1. `git add`/`git commit` the current working-tree changes (see "What Is Left" — uncommitted work) — do this first, before any new code, to avoid losing this session's fixes.
2. `mobile/lib/features/goals/` (new) — mirror the structure already established in `mobile/lib/features/transactions/` (`domain/`, `data/`, `presentation/providers/`, `presentation/screens/`) against the existing `apps/goals` backend (`GoalSerializer`, `AddProgressSerializer`).
3. `mobile/lib/features/analytics/` (new) — chart screen(s) consuming `apps/analytics/urls.py` endpoints (`category-breakdown`, `monthly-trend`, `monthly-report`), using the already-installed `fl_chart` package.
4. `mobile/lib/features/categories/presentation/` and `mobile/lib/features/cards/presentation/` — extend the existing read-only data layers with actual management screens.
5. `mobile/test/` — backfill tests once each feature above stabilizes, rather than at the very end.

This order follows the dependency chain visible in the code: Goals and Analytics have zero mobile blockers (backend fully ready) and deliver the most product-brief value next (savings goals + the "data analytics" differentiator called out in the original product brief). Categories/Cards management and offline-first are lower urgency since the app is currently usable without them (defaults exist server-side).
