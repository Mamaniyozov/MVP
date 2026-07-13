from decimal import Decimal

from rest_framework import serializers

from apps.goals.models import Goal


class GoalSerializer(serializers.ModelSerializer):
    progress_percent = serializers.SerializerMethodField()

    class Meta:
        model = Goal
        fields = [
            "id",
            "name",
            "target_amount",
            "current_amount",
            "deadline",
            "created_at",
            "progress_percent",
        ]
        read_only_fields = ["id", "created_at", "progress_percent"]

    def get_progress_percent(self, obj) -> float:
        if not obj.target_amount:
            return 0.0
        return round(float(obj.current_amount) / float(obj.target_amount) * 100, 2)


class AddProgressSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=14, decimal_places=2, min_value=Decimal("0.01"))
