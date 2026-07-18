from django.db.models import F
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
        goal = self.get_object()
        serializer = AddProgressSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        amount = serializer.validated_data["amount"]

        new_amount = goal.current_amount + amount
        if new_amount > goal.target_amount:
            raise ValidationError({"amount": "Bu miqdor maqsad summasidan (target_amount) oshib ketadi."})

        goal.current_amount = F("current_amount") + amount
        goal.save(update_fields=["current_amount"])

        goal.refresh_from_db()
        return Response(GoalSerializer(goal).data)
