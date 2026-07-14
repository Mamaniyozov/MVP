# Finance App

A personal finance tracking application: a Django REST API backend paired
with a Flutter mobile client. Track income and expenses, organize them by
category, set savings goals, and get monthly analytics — all scoped per
authenticated user.

## Project Structure

```
.
├── apps/                # Django apps (one per domain)
│   ├── users/            # registration, JWT auth, profile + default categories
│   ├── categories/       # expense/income categories
│   ├── cards/             # payment cards / accounts
│   ├── transactions/     # income & expense records
│   ├── goals/             # savings goals
│   └── analytics/        # category breakdown, monthly trend & report
├── config/               # Django project settings, root URLconf, WSGI/ASGI
├── mobile/                # Flutter client (Riverpod + go_router + Dio)
├── manage.py
├── docker-compose.yml     # db + backend services
└── requirements.txt
```

## Backend Stack

- Python 3.12, Django 5.x, Django REST Framework
- PostgreSQL 16
- `djangorestframework-simplejwt` (JWT auth)
- `drf-spectacular` (OpenAPI schema / Swagger UI)
- `django-filter`, `django-cors-headers`, `django-environ`
- `pytest` + `pytest-django` (tests)

## Mobile Stack (`mobile/`)

- Flutter (SDK ^3.4)
- `flutter_riverpod` — state management
- `go_router` — navigation
- `dio` — HTTP client
- `flutter_secure_storage` — token storage
- `fl_chart` — analytics charts

## Getting Started (Docker — recommended)

1. Copy the env template and fill in real values:

   ```bash
   cp .env.example .env
   ```

2. Build and start the stack:

   ```bash
   docker-compose up --build
   ```

   This starts two services:
   - `db` — PostgreSQL 16
   - `backend` — Django dev server on http://localhost:8000

3. Apply migrations (first run):

   ```bash
   docker-compose run backend python manage.py migrate
   ```

4. (Optional) create a superuser for `/admin/`:

   ```bash
   docker-compose run backend python manage.py createsuperuser
   ```

## Getting Started (local, without Docker)

1. Create and activate a virtualenv, then install dependencies:

   ```bash
   python -m venv venv
   venv\Scripts\activate        # Windows
   pip install -r requirements.txt
   ```

2. Copy `.env.example` to `.env` and point `POSTGRES_HOST` at a local
   PostgreSQL instance (e.g. `localhost`) instead of `db`.

3. Run migrations and start the dev server:

   ```bash
   python manage.py migrate
   python manage.py runserver
   ```

## Environment Variables

See `.env.example` for the full list. Key variables:

| Variable | Description |
|---|---|
| `DEBUG` | Django debug mode |
| `SECRET_KEY` | Django secret key — change before deploying |
| `ALLOWED_HOSTS` | Comma-separated allowed hosts |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | Database credentials |
| `POSTGRES_HOST` | `db` inside Docker, `localhost` for local dev |
| `DATABASE_URL` | Full Postgres connection string |
| `CORS_ALLOWED_ORIGINS` | Allowed origins for the Flutter client |

## API Docs

- Swagger UI: http://localhost:8000/api/schema/swagger-ui/
- Raw OpenAPI schema: http://localhost:8000/api/schema/

## Auth Endpoints

- `POST /api/v1/auth/register/` — `email`, `password`, `password2`
- `POST /api/v1/auth/login/` — `email`, `password` → `access` + `refresh`
- `POST /api/v1/auth/refresh/` — `refresh` → new `access`

Registering a user automatically creates a `UserProfile` and a default set of
expense/income categories (via a `post_save` signal on `User`, implemented in
`apps/users/services.py`).

## Resource Endpoints

All under `/api/v1/`, JWT-authenticated, scoped to the requesting user:

- `categories/`
- `cards/`
- `transactions/`
- `goals/`

## Analytics Endpoints

All under `/api/v1/analytics/`, JWT-authenticated:

- `GET category-breakdown/?month=&year=` — expense totals per category for a
  given month, with percentage share, sorted descending
- `GET monthly-trend/?months=` — income vs. expense totals for the last N
  months (defaults to 6), chronological, zero-filled for months with no data
- `GET monthly-report/?month=&year=` — current vs. previous month comparison
  (income/expense/savings, % change, fastest-growing expense category) plus
  human-readable insight summaries

## Running Tests

```bash
docker-compose run backend pytest -v
```

Or locally (with the venv active):

```bash
pytest -v
```
