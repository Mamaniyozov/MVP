from django.contrib import admin

from apps.categories.models import Category


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "type", "user", "is_default"]
    list_filter = ["type", "is_default"]
    search_fields = ["name"]
