import os
from celery import Celery
from celery.schedules import crontab

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('hisob')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django apps.
app.autodiscover_tasks()

from celery.signals import task_prerun, task_postrun
import time

# Task monitoring
active_tasks = {}

@task_prerun.connect
def task_prerun_handler(task_id, task, *args, **kwargs):
    active_tasks[task_id] = {
        'name': task.name,
        'started_at': time.time(),
    }

@task_postrun.connect
def task_postrun_handler(task_id, task, *args, **kwargs):
    if task_id in active_tasks:
        duration = time.time() - active_tasks[task_id]['started_at']
        print(f"Task {task.name} completed in {duration:.2f}s")
        del active_tasks[task_id]

# Celery Beat Schedule
app.conf.beat_schedule = {
    'check-upcoming-debts': {
        'task': 'apps.debts.tasks.check_upcoming_debt_payments',
        'schedule': crontab(hour=9, minute=0),  # Har kuni 9:00
    },
    'create-recurring-transactions': {
        'task': 'apps.transactions.tasks.create_recurring_transactions',
        'schedule': crontab(hour=0, minute=1),  # Har kuni 00:01
    },
    'generate-monthly-reports': {
        'task': 'apps.analytics.tasks.generate_monthly_reports',
        'schedule': crontab(day_of_month=1, hour=2, minute=0),  # Har oy 1-sanasi 2:00
    },
}
