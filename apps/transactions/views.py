from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets
from rest_framework.filters import OrderingFilter
from rest_framework.permissions import IsAuthenticated

from apps.transactions.filters import TransactionFilter
from apps.transactions.models import Transaction
from apps.transactions.pagination import TransactionPagination
from apps.transactions.serializers import TransactionSerializer


class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = TransactionPagination
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_class = TransactionFilter
    ordering_fields = ["date", "amount", "created_at"]
    ordering = ["-date"]

    def get_queryset(self):
        return Transaction.objects.filter(user=self.request.user).select_related("category", "card")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
