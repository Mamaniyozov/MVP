import django_filters

from apps.transactions.models import Transaction


class TransactionFilter(django_filters.FilterSet):
    date_from = django_filters.DateFilter(
        field_name="date", lookup_expr="gte", help_text="Boshlanish sanasi (YYYY-MM-DD), shu kunni ham qamrab oladi."
    )
    date_to = django_filters.DateFilter(
        field_name="date", lookup_expr="lte", help_text="Tugash sanasi (YYYY-MM-DD), shu kunni ham qamrab oladi."
    )

    class Meta:
        model = Transaction
        fields = ["category", "type", "card", "date_from", "date_to"]
