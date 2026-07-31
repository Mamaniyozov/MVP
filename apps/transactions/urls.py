from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.transactions.views import (
    RecurringTransactionViewSet,
    TransactionExportView,
    TransactionViewSet,
)

router = DefaultRouter()
router.register("transactions/recurring", RecurringTransactionViewSet, basename="recurring-transaction")
router.register("transactions", TransactionViewSet, basename="transaction")


urlpatterns = [
    path("transactions/export/", TransactionExportView.as_view(), name="transaction-export"),
] + router.urls

