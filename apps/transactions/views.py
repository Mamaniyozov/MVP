from decimal import Decimal

from django.db import transaction as db_transaction
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets
from rest_framework.exceptions import ValidationError
from rest_framework.filters import OrderingFilter
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView


from apps.goals.models import Goal
from apps.transactions.filters import TransactionFilter
from apps.transactions.models import RecurringTransaction, Transaction
from apps.transactions.pagination import TransactionPagination
from apps.transactions.serializers import RecurringTransactionSerializer, TransactionSerializer



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
            "category", "account", "goal"
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


class TransactionExportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        import csv
        from django.utils import timezone
        from django.http import HttpResponse

        def sanitize_csv(val):
            if not isinstance(val, str):
                val = str(val)
            if val and val[0] in ('=', '+', '-', '@', '\t', '\r'):
                return f"'{val}"
            return val

        queryset = Transaction.objects.filter(user=request.user).select_related("category", "account")

        # Apply basic filters
        date_from = request.query_params.get("date_from")
        date_to = request.query_params.get("date_to")
        tx_type = request.query_params.get("type")
        category_id = request.query_params.get("category")

        if date_from:
            queryset = queryset.filter(date__gte=date_from)
        if date_to:
            queryset = queryset.filter(date__lte=date_to)
        if tx_type:
            queryset = queryset.filter(type=tx_type)
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        queryset = queryset.order_by("-date")

        filename = f"transactions_{timezone.localdate().strftime('%Y%m%d')}.csv"
        response = HttpResponse(content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = f'attachment; filename="{filename}"'

        writer = csv.writer(response)
        writer.writerow(["Sana", "Turi", "Kategoriya", "Summa (UZS)", "Karta", "Izoh"])

        for tx in queryset:
            type_display = "Daromad" if tx.type == "income" else "Xarajat"
            account_name = tx.account.name if tx.account else "-"
            writer.writerow([
                tx.date, 
                type_display, 
                sanitize_csv(tx.category.name), 
                tx.amount, 
                sanitize_csv(account_name), 
                sanitize_csv(tx.note)
            ])

        return response


class RecurringTransactionViewSet(viewsets.ModelViewSet):
    serializer_class = RecurringTransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return RecurringTransaction.objects.filter(user=self.request.user).select_related("category", "account")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


