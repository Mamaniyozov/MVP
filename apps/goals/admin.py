from django.contrib import admin

from apps.goals.models import Goal


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "user", "target_amount", "current_amount", "deadline"]
