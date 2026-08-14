# 🚀 Hisob - Personal Finance Tracker

![Python](https://img.shields.io/badge/Python-3.12-blue.svg)
![Django](https://img.shields.io/badge/Django-5.x-success.svg)
![Next.js](https://img.shields.io/badge/Next.js-14-black.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)
![Celery](https://img.shields.io/badge/Celery-Task_Queue-green.svg)

**Hisob** is a modern, full-stack personal finance tracking application. It features a robust Django REST Framework backend and a sleek Next.js (App Router, TailwindCSS) web client utilizing the latest "Pro Max 3D Panel" Neumorphism UI.

---

## ✨ Features

- **🔐 Secure Authentication**: Next-gen security using `HttpOnly` Cookies for JWT access and refresh tokens, automatic token refreshing (Axios Interceptors), brute-force protection (Django Axes), and Rate Limiting.
- **💰 Financial Management**: Advanced management with multiple apps: `accounts`, `merchants`, `tags`, and flexible `TransactionSplit` models.
- **📈 Investments & Debts**: Track stocks, crypto, and loans with built-in payoff schedulers and profit/loss calculations.
- **🎯 Budgets & Goals**: Smart rollover budgets, auto-saving goals, and priority tracking.
- **📊 Advanced Analytics**: Automated celery tasks to generate monthly reports and beautiful Recharts visualizations.
- **🛡️ Production-Ready**: Pre-configured for WAFs (Cloudflare/AWS), structured logging, Prometheus metrics, and Sentry error tracking.
- **🐳 Dockerized**: Spin up the entire full-stack ecosystem (Postgres, Redis, Django, Celery, Next.js) with a single command.

---

## 🛠️ Tech Stack

### Backend
- **Framework**: Django 5.x & Django REST Framework
- **Database**: PostgreSQL 16
- **Caching & Async Tasks**: Redis 7, Celery
- **Security**: djangorestframework-simplejwt, django-axes, django-ratelimit
- **Documentation**: drf-spectacular (Swagger UI / OpenAPI)

### Frontend (Web)
- **Framework**: Next.js (App Router), TypeScript
- **Styling**: Tailwind CSS (Pro Max Neumorphism)
- **State & Data Fetching**: Axios (with interceptors), React Context
- **Visualizations**: Recharts

---

## 🚀 Quick Start (Docker)

The easiest way to run the entire ecosystem is via Docker.

### 1. Environment Setup
Copy the environment template and configure your secrets:
```bash
cp .env.example .env
```

### 2. Build and Run
```bash
docker-compose up -d --build
```
*This starts the following networked services:*
- **`db`**: PostgreSQL on `:5432`
- **`redis`**: Redis Cache on `:6380`
- **`backend`**: Django API at `http://localhost:8000`
- **`celery`**: Async task worker for Analytics and Reports
- **`celery-beat`**: Async periodic task scheduler
- **`web`**: Next.js Client at `http://localhost:3000`

### 3. Initialize Database
Run migrations and create an admin user on the first run:
```bash
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py createsuperuser
```

🎉 **You're all set!** 
- Access the **Web App** at [http://localhost:3000](http://localhost:3000)
- Access the **API Docs (Swagger)** at [http://localhost:8000/api/schema/swagger-ui/](http://localhost:8000/api/schema/swagger-ui/)

---

## 🔗 Connecting the Frontend & Backend

The frontend (`web`) and backend (`backend`) are tightly integrated with a focus on security:
- **HttpOnly Cookies**: The authentication flow does not expose JWT tokens to `localStorage`. The backend sets `HttpOnly` cookies, preventing XSS attacks.
- **Axios Configuration**: The Next.js client uses `withCredentials: true` in its Axios configuration.
- **Automated Renewals**: Tokens are refreshed silently in the background when the `401` interceptor is triggered.

---

## 🚀 Production Deployment Guide

Before deploying Hisob to a production server, ensure the following checklist is completed to guarantee maximum security, performance, and reliability.

### 1. Environment & Secrets
Configure your `.env.production` file completely, replacing all placeholders with strong random values. Ensure `DEBUG=False` and `ALLOWED_HOSTS` includes your domain (e.g. `hisob.uz`, `www.hisob.uz`).

### 2. SSL/TLS Certificates
Run Let's Encrypt with Certbot to secure all HTTP traffic:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d hisob.uz -d www.hisob.uz
sudo systemctl enable certbot.timer
```

### 3. Database Backups
Automate your PostgreSQL database backups via cron jobs:
```bash
#!/bin/bash
BACKUP_DIR="/backups/hisob"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_ID=$(docker ps -q -f name=finance_db)
mkdir -p $BACKUP_DIR
docker exec $CONTAINER_ID pg_dump -U finance_user finance_db > $BACKUP_DIR/backup_$DATE.sql
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
# aws s3 cp $BACKUP_DIR/backup_$DATE.sql s3://hisob-backups/
```

### 4. CI/CD & GitHub Actions
Set up GitHub Actions to automatically run `pytest` and code linting before SSHing into your production server to pull, rebuild, and restart the Docker containers.

### 5. Performance Optimizations
- **Database Pooling**: Set `CONN_MAX_AGE=600` in `DATABASES` settings.
- **Query Optimization**: Use `select_related` and `prefetch_related` on your heavy viewsets (like Transactions) to avoid N+1 queries.
- **Static Files**: Use `whitenoise.storage.CompressedManifestStaticFilesStorage`.

### 6. Final Deployment Command
```bash
cd /opt/hisob
git pull origin main
docker-compose pull
docker-compose up -d --build
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py collectstatic --noinput
docker-compose restart
```

### 7. Security Audit
- [x] JWT HttpOnly cookies
- [x] Token blacklisting
- [x] Rate limiting (e.g., login: 5/hour)
- [x] Parameterized queries (Django ORM)
- [x] CORS configured
- [x] CSRF protection
- [x] Health checks
- [x] Container isolation
- [ ] 2FA (TOTP) - **Future**
- [ ] Row-level security (RLS) - **Future**
- [ ] WAF (Cloudflare/AWS) - **Future**
