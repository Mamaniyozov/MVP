from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.users.services import create_default_categories, create_user_profile


@receiver(post_save, sender=User)
def handle_user_created(sender, instance, created, **kwargs):
    if created:
        create_user_profile(instance)
        create_default_categories(instance)
