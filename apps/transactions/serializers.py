from rest_framework import serializers

from apps.transactions.models import RecurringTransaction, Transaction



class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = [
            "id",
            "category",
            "account",
            "goal",
            "amount",
            "type",
            "date",
            "note",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def validate(self, attrs):
        request = self.context["request"]

        category = attrs.get("category", getattr(self.instance, "category", None))
        if category is not None and category.user_id is not None and category.user_id != request.user.id:
            raise serializers.ValidationError({"category": "Category does not belong to this user."})

        account = attrs.get("account", getattr(self.instance, "account", None))
        if account is not None and account.user_id != request.user.id:
            raise serializers.ValidationError({"account": "Account does not belong to this user."})

        goal = attrs.get("goal", getattr(self.instance, "goal", None))
        tx_type = attrs.get("type", getattr(self.instance, "type", None))
        if goal is not None:
            if goal.user_id != request.user.id:
                raise serializers.ValidationError({"goal": "Goal does not belong to this user."})
            if tx_type != "expense":
                raise serializers.ValidationError(
                    {"goal": "Maqsad faqat xarajat turidagi tranzaksiyalarga bog'lanishi mumkin."}
                )

        return attrs


class RecurringTransactionSerializer(serializers.ModelSerializer):
    is_active = serializers.BooleanField(default=True)

    class Meta:
        model = RecurringTransaction
        fields = [
            "id",
            "category",
            "account",
            "amount",
            "type",
            "frequency",
            "next_date",
            "note",
            "is_active",
            "created_at",
        ]

        read_only_fields = ["id", "created_at"]

    def validate(self, attrs):
        request = self.context["request"]
        category = attrs.get("category", getattr(self.instance, "category", None))
        if category is not None and category.user_id is not None and category.user_id != request.user.id:
            raise serializers.ValidationError({"category": "Category does not belong to this user."})

        account = attrs.get("account", getattr(self.instance, "account", None))
        if account is not None and account.user_id != request.user.id:
            raise serializers.ValidationError({"account": "Account does not belong to this user."})

        return attrs

