from django.contrib import admin

from apps.cards.models import Card


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "last4", "user"]
