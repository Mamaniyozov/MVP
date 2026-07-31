from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from apps.budgets.models import Budget
from apps.budgets.serializers import BudgetSerializer


class BudgetViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = BudgetSerializer

    def get_queryset(self):
        queryset = Budget.objects.filter(user=self.request.user).select_related("category")
        month = self.request.query_params.get("month")
        year = self.request.query_params.get("year")
        if month:
            queryset = queryset.filter(month=month)
        if year:
            queryset = queryset.filter(year=year)
        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
