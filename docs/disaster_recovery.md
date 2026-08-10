# Disaster Recovery & Backup Plan

## 1. Database Backup Strategy

### Automated Daily Backups
- Script: `scripts/backup_db.sh`
- Schedule: Daily at 02:00 UTC via cron or CI/CD
- Retention: 30 days (configurable via `RETENTION_DAYS`)
- Storage: Local `/backups/` directory (mount to persistent volume in production)

### Manual Backup
```bash
export PGPASSWORD="$POSTGRES_PASSWORD"
./scripts/backup_db.sh
```

### Restore from Backup
```bash
gunzip -c /backups/finance_db_YYYYMMDD_HHMMSS.sql.gz | \
  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
```

## 2. Point-In-Time Recovery (PITR)

For production PostgreSQL with WAL archiving:

1. Enable WAL archiving in `postgresql.conf`:
   ```
   wal_level = replica
   archive_mode = on
   archive_command = 'cp %p /wal_archive/%f'
   ```
2. Take a base backup: `pg_basebackup -D /backup/base -Ft -z`
3. To recover to a specific time:
   ```
   restore_command = 'cp /wal_archive/%f %p'
   recovery_target_time = '2026-08-10 10:00:00'
   ```

## 3. Application Recovery

### Backend
1. Restore PostgreSQL from latest backup
2. Run migrations: `python manage.py migrate`
3. Restart Gunicorn: `docker compose restart backend`
4. Verify health: `curl http://localhost:8000/api/v1/health/`

### Frontend
1. Rebuild: `docker compose build web`
2. Restart: `docker compose restart web`
3. Verify: Access `http://localhost:3000`

## 4. Recovery Time Objectives

| Metric | Target |
|--------|--------|
| RPO (Recovery Point Objective) | < 24 hours (daily backups) |
| RTO (Recovery Time Objective) | < 1 hour |

## 5. Monitoring & Alerts

- Sentry: Application error tracking (`SENTRY_DSN` env var)
- Prometheus: `/metrics` endpoint for system metrics
- Health check: `/api/v1/health/` endpoint
