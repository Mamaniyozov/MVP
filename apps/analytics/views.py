from datetime import date

from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.analytics.services import get_category_breakdown, get_monthly_report, get_monthly_trend

MONTH_PARAM = OpenApiParameter(
    "month", int, description="Oy raqami (1-12). Berilmasa joriy oy ishlatiladi.", required=False
)
YEAR_PARAM = OpenApiParameter(
    "year", int, description="Yil (masalan 2026). Berilmasa joriy yil ishlatiladi.", required=False
)


def _int_param(params, name, default, min_value=None, max_value=None):
    raw = params.get(name)
    if raw in (None, ""):
        value = default
    else:
        try:
            value = int(raw)
        except (TypeError, ValueError):
            raise ValidationError({name: "Butun son bo'lishi kerak."})
    if max_value is not None and not (min_value <= value <= max_value):
        raise ValidationError({name: f"{min_value}-{max_value} oralig'ida bo'lishi kerak."})
    if min_value is not None and value < min_value:
        raise ValidationError({name: f"Kamida {min_value} bo'lishi kerak."})
    return value


class CategoryBreakdownView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        parameters=[MONTH_PARAM, YEAR_PARAM],
        description=(
            "Berilgan oy uchun faqat xarajat (expense) tranzaksiyalarini kategoriya bo'yicha "
            "guruhlab, har birining summasi va umumiy summadan foizini qaytaradi. "
            "Natija foiz bo'yicha kamayish tartibida."
        ),
    )
    def get(self, request):
        today = date.today()
        month = _int_param(request.query_params, "month", today.month, min_value=1, max_value=12)
        year = _int_param(request.query_params, "year", today.year, min_value=1)
        return Response(get_category_breakdown(request.user, month, year))


class MonthlyTrendView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        parameters=[
            OpenApiParameter(
                "months",
                int,
                description="Necha oylik trend ko'rsatilsin (joriy oydan orqaga). Standart: 6.",
                required=False,
            )
        ],
        description=(
            "Oxirgi N oy uchun (joriy oy bilan tugaydigan, xronologik tartibda) har oy bo'yicha "
            "income va expense summasini qaytaradi. Tranzaksiya bo'lmagan oylar 0 bilan to'ldiriladi."
        ),
    )
    def get(self, request):
        months = _int_param(request.query_params, "months", 6, min_value=1)
        return Response(get_monthly_trend(request.user, months))


class MonthlyReportView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        parameters=[MONTH_PARAM, YEAR_PARAM],
        description=(
            "Joriy va o'tgan oy uchun income/expense/savings solishtiruvi, foiz o'zgarishlari, "
            "eng ko'p o'sgan xarajat kategoriyasi (kamida 20% o'sish bilan) va o'zbek tilidagi "
            "oddiy insight xulosalarni qaytaradi."
        ),
    )
    def get(self, request):
        today = date.today()
        month = _int_param(request.query_params, "month", today.month, min_value=1, max_value=12)
        year = _int_param(request.query_params, "year", today.year, min_value=1)
        return Response(get_monthly_report(request.user, month, year))
