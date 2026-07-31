from decimal import Decimal

from django.db.models import Sum
from rest_framework import serializers

from apps.budgets.models import Budget
from apps.categories.models import Category
from apps.categories.serializers import CategorySerializer
from apps.transactions.models import Transaction


class BudgetSerializer(serializers.ModelSerializer):
    category_detail = CategorySerializer(source="category", read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), source="category", write_only=True
    )
    spent_amount = serializers.SerializerMethodField()
    remaining_amount = serializers.SerializerMethodField()
    spent_percent = serializers.SerializerMethodField()
    is_exceeded = serializers.SerializerMethodField()

    class Meta:
        model = Budget
        fields = [
            "id",
            "category_id",
            "category_detail",
            "amount_limit",
            "month",
            "year",
            "spent_amount",
            "remaining_amount",
            "spent_percent",
            "is_exceeded",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def _get_spent(self, obj) -> Decimal:
        spent = Transaction.objects.filter(
            user=obj.user,
            category=obj.category,
            type="expense",
            date__year=obj.year,
            date__month=obj.month,
        ).aggregate(total=Sum("amount"))["total"]
        return spent if spent is not None else Decimal("0")

    def get_spent_amount(self, obj) -> Decimal:
        return self._get_spent(obj)

    def get_remaining_amount(self, obj) -> Decimal:
        spent = self._get_spent(obj)
        remaining = obj.amount_limit - spent
        return remaining if remaining > Decimal("0") else Decimal("0")

    def get_spent_percent(self, obj) -> float:
        spent = self._get_spent(obj)
        if not obj.amount_limit:
            return 0.0
        pct = (spent / obj.amount_limit) * Decimal("100")
        return round(float(pct), 2)

    def get_is_exceeded(self, obj) -> bool:
        spent = self._get_spent(obj)
        return spent > obj.amount_limit

    def validate(self, attrs):
        user = self.context["request"].user
        category = attrs.get("category")
        month = attrs.get("month")
        year = attrs.get("year")

        if category and category.user is not None and category.user != user:
            raise serializers.ValidationError({"category_id": "Ushbu kategoriya sizga tegishli emas."})

        # Check uniqueness on creation
        if not self.instance:
            if Budget.objects.filter(user=user, category=category, month=month, year=year).exists():
                raise serializers.ValidationError(
                    "Ushbu kategoriya va oy uchun allaqachon byudjet kiritilgan."
                )
        return attrs
