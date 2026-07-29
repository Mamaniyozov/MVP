from decimal import Decimal

from django.db import transaction as db_transaction
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets
from rest_framework.exceptions import ValidationError
from rest_framework.filters import OrderingFilter
from rest_framework.permissions import IsAuthenticated

from apps.goals.models import Goal
from apps.transactions.filters import TransactionFilter
from apps.transactions.models import Transaction
from apps.transactions.pagination import TransactionPagination
from apps.transactions.serializers import TransactionSerializer


def _adjust_goal_amount(user, goal_id, delta):
    """Applies `delta` (positive or negative) to a goal's current_amount.

    Locks the row so concurrent transaction writes against the same goal
    can't race past the target_amount cap. Only checked on increase —
    reversing a deleted/edited contribution should never be rejected.
    """
    if goal_id is None or delta == 0:
        return

    goal = Goal.objects.select_for_update().get(pk=goal_id, user=user)
    new_amount = goal.current_amount + delta
    if delta > 0 and new_amount > goal.target_amount:
        raise ValidationError({"goal": "Bu miqdor maqsad summasidan (target_amount) oshib ketadi."})
    if new_amount < 0:
        new_amount = Decimal("0")

    goal.current_amount = new_amount
    goal.save(update_fields=["current_amount"])


class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = TransactionPagination
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_class = TransactionFilter
    ordering_fields = ["date", "amount", "created_at"]
    ordering = ["-date"]

    def get_queryset(self):
        return Transaction.objects.filter(user=self.request.user).select_related(
            "category", "card", "goal"
        )

    def perform_create(self, serializer):
        with db_transaction.atomic():
            instance = serializer.save(user=self.request.user)
            if instance.goal_id:
                _adjust_goal_amount(self.request.user, instance.goal_id, instance.amount)

    def perform_update(self, serializer):
        old_goal_id = serializer.instance.goal_id
        old_amount = serializer.instance.amount

        with db_transaction.atomic():
            instance = serializer.save()
            new_goal_id = instance.goal_id
            new_amount = instance.amount

            if old_goal_id == new_goal_id:
                if old_goal_id is not None:
                    _adjust_goal_amount(self.request.user, old_goal_id, new_amount - old_amount)
            else:
                if old_goal_id is not None:
                    _adjust_goal_amount(self.request.user, old_goal_id, -old_amount)
                if new_goal_id is not None:
                    _adjust_goal_amount(self.request.user, new_goal_id, new_amount)

    def perform_destroy(self, instance):
        with db_transaction.atomic():
            if instance.goal_id:
                _adjust_goal_amount(self.request.user, instance.goal_id, -instance.amount)
            instance.delete()
