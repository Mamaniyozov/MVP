"""
Data retention management command.
Deletes transactions older than the specified retention period (default: 365 days).
Usage: python manage.py purge_old_data --days 365 --dry-run
"""
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.transactions.models import Transaction


class Command(BaseCommand):
    help = "Purge transactions older than N days (default: 365). Use --dry-run to preview."

    def add_arguments(self, parser):
        parser.add_argument(
            "--days", type=int, default=365,
            help="Delete transactions older than this many days (default: 365)."
        )
        parser.add_argument(
            "--dry-run", action="store_true",
            help="Preview the count of records to be deleted without actually deleting."
        )

    def handle(self, *args, **options):
        days = options["days"]
        dry_run = options["dry_run"]
        cutoff = timezone.localdate() - timedelta(days=days)

        qs = Transaction.objects.filter(date__lt=cutoff)
        count = qs.count()

        if dry_run:
            self.stdout.write(
                self.style.WARNING(f"[DRY RUN] Would delete {count} transactions older than {cutoff}.")
            )
            return

        if count == 0:
            self.stdout.write(self.style.SUCCESS(f"No transactions older than {cutoff}. Nothing to purge."))
            return

        deleted, breakdown = qs.delete()
        self.stdout.write(
            self.style.SUCCESS(f"Purged {deleted} records older than {cutoff}. Breakdown: {breakdown}")
        )
