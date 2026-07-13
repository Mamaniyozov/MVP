from rest_framework import serializers

from apps.transactions.models import Transaction


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = [
            "id",
            "category",
            "card",
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

        card = attrs.get("card", getattr(self.instance, "card", None))
        if card is not None and card.user_id != request.user.id:
            raise serializers.ValidationError({"card": "Card does not belong to this user."})

        return attrs
