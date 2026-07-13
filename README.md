# Finance App — Backend

Django + DRF API for the personal finance tracking app.

## Stack

- Python 3.12, Django 5.x, Django REST Framework
- PostgreSQL 16
- djangorestframework-simplejwt (JWT auth)
- drf-spectacular (OpenAPI schema / Swagger UI)
- pytest-django (tests)

## Running with Docker

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

## API docs

- Swagger UI: http://localhost:8000/api/schema/swagger-ui/
- Raw OpenAPI schema: http://localhost:8000/api/schema/

## Auth endpoints

- `POST /api/v1/auth/register/` — `email`, `password`, `password2`
- `POST /api/v1/auth/login/` — `email`, `password` → `access` + `refresh`
- `POST /api/v1/auth/refresh/` — `refresh` → new `access`

Registering a user automatically creates a `UserProfile` and a default set of
expense/income categories (via a `post_save` signal on `User`, implemented in
`apps/users/services.py`).

## Resource endpoints

All under `/api/v1/`, JWT-authenticated, scoped to the requesting user:

- `categories/`
- `cards/`
- `transactions/`
- `goals/`

## Running tests

```bash
docker-compose run backend pytest -v
```
