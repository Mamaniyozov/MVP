from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from apps.cards.models import Card
from apps.cards.serializers import CardSerializer


class CardViewSet(viewsets.ModelViewSet):
    serializer_class = CardSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Card.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
