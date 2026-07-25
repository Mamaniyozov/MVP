from django.db import transaction
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.goals.models import Goal
from apps.goals.serializers import AddProgressSerializer, GoalSerializer


class GoalViewSet(viewsets.ModelViewSet):
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Goal.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @extend_schema(
        request=AddProgressSerializer,
        responses=GoalSerializer,
        description=(
            "Goal current_amount qiymatiga 'amount'ni qo'shadi. "
            "Agar natija target_amount'dan oshib ketsa, xato qaytariladi."
        ),
    )
    @action(detail=True, methods=["post"], url_path="add-progress")
    def add_progress(self, request, pk=None):
        serializer = AddProgressSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        amount = serializer.validated_data["amount"]

        # Qator lock ostida o'qish + tekshiruv + yozish bitta tranzaksiyada bo'lmasa,
        # ikki parallel so'rov target_amount limitidan oshirib yuborishi mumkin.
        with transaction.atomic():
            goal = get_object_or_404(self.get_queryset().select_for_update(), pk=pk)

            new_amount = goal.current_amount + amount
            if new_amount > goal.target_amount:
                raise ValidationError({"amount": "Bu miqdor maqsad summasidan (target_amount) oshib ketadi."})

            goal.current_amount = new_amount
            goal.save(update_fields=["current_amount"])

        return Response(GoalSerializer(goal).data)
