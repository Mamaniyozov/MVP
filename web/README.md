# Hisob — web

Next.js (App Router, TypeScript, Tailwind) client for the same Django REST
API the Flutter mobile app uses. Same account, same data — login on either
client and both stay in sync through the backend.

## Run with Docker (recommended — matches the backend's setup)

From the repo root:
```
docker compose up --build
```
Starts `db` (Postgres), `backend` (Django on :8000) and `web` (Next.js dev
server on :3000) together, networked so the web container can already reach
`backend`. The browser talks to the backend via the **host-mapped** port
(`http://localhost:8000/api/v1`), not the internal service name — set with
`WEB_API_BASE_URL` in the repo-root `.env` if you need to override it.

## Run locally (without Docker)

1. Backend must be running first (from the repo root):
   ```
   python manage.py runserver
   ```
   By default `DEBUG=True` sets `CORS_ALLOW_ALL_ORIGINS=True` (see
   `config/settings.py`), so the web app's `localhost:3000` origin is
   allowed automatically in dev. For a non-DEBUG environment, add the web
   origin explicitly via `CORS_ALLOWED_ORIGINS=https://your-web-domain` in
   the backend's env.

2. Web app:
   ```
   cd web
   npm install
   cp .env.local.example .env.local   # adjust NEXT_PUBLIC_API_BASE_URL if needed
   npm run dev
   ```
   Opens on http://localhost:3000, talking to
   `NEXT_PUBLIC_API_BASE_URL` (defaults to `http://127.0.0.1:8000/api/v1`).

## What's implemented

Mirrors the mobile app's feature set against the same `/api/v1/` endpoints:
auth (login/register/JWT refresh), transactions (list/filter/create/delete),
categories & cards management (create/edit/delete — a gap the mobile app
still has, see `goals.md`), savings goals (create/add-progress/delete), and
analytics (category breakdown, 6-month trend, monthly report) with charts
built per the `dataviz` skill's mark/color/interaction rules.

## Structure

- `src/app/(auth)/` — login/register, split-screen layout
- `src/app/(app)/` — sidebar shell + the authenticated pages
- `src/lib/api/` — axios client with JWT refresh interceptor + typed endpoints
- `src/lib/auth/AuthContext.tsx` — session state, mirrors the mobile app's
  token-refresh-then-force-logout pattern
- `src/components/charts/` — recharts wrappers using the validated
  categorical/status palette from `src/lib/chartPalette.ts`
