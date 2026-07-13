from rest_framework import serializers

from apps.cards.models import Card


class CardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Card
        fields = ["id", "name", "last4"]
        read_only_fields = ["id"]
