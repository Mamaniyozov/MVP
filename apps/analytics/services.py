from datetime import date
from decimal import Decimal

from django.db.models import Count, Sum
from django.db.models.functions import ExtractMonth, ExtractYear

from apps.transactions.models import Transaction


def _shift_month(year: int, month: int, offset: int) -> tuple[int, int]:
    total = year * 12 + (month - 1) + offset
    new_year, new_month0 = divmod(total, 12)
    return new_year, new_month0 + 1


def _percent_change(current, previous):
    if not previous:
        return None
    return round(float(current - previous) / float(previous) * 100, 2)


def get_category_breakdown(user, month: int, year: int) -> list[dict]:
    rows = list(
        Transaction.objects.filter(user=user, type="expense", date__year=year, date__month=month)
        .values("category__name")
        .annotate(total=Sum("amount"))
        .order_by("-total")
    )

    grand_total = sum((row["total"] for row in rows), Decimal("0"))
    if not grand_total:
        return []

    return [
        {
            "category": row["category__name"],
            "total": row["total"],
            "percent": round(float(row["total"]) / float(grand_total) * 100, 2),
        }
        for row in rows
    ]


def get_monthly_trend(user, months: int = 6) -> list[dict]:
    today = date.today()
    month_keys = [_shift_month(today.year, today.month, -i) for i in range(months - 1, -1, -1)]

    rows = (
        Transaction.objects.filter(user=user)
        .annotate(y=ExtractYear("date"), m=ExtractMonth("date"))
        .values("y", "m", "type")
        .annotate(total=Sum("amount"))
    )
    totals = {(row["y"], row["m"], row["type"]): row["total"] for row in rows}

    return [
        {
            "month": f"{year:04d}-{month:02d}",
            "income": totals.get((year, month, "income"), Decimal("0")),
            "expense": totals.get((year, month, "expense"), Decimal("0")),
        }
        for year, month in month_keys
    ]


def _month_totals(user, year: int, month: int) -> dict:
    rows = (
        Transaction.objects.filter(user=user, date__year=year, date__month=month)
        .values("type")
        .annotate(total=Sum("amount"))
    )
    totals = {"income": Decimal("0"), "expense": Decimal("0")}
    for row in rows:
        totals[row["type"]] = row["total"]

    return {
        "income": totals["income"],
        "expense": totals["expense"],
        "savings": totals["income"] - totals["expense"],
    }


def _category_totals(user, year: int, month: int) -> dict:
    rows = (
        Transaction.objects.filter(user=user, type="expense", date__year=year, date__month=month)
        .values("category__name")
        .annotate(total=Sum("amount"), count=Count("id"))
    )
    return {row["category__name"]: (row["total"], row["count"]) for row in rows}


def get_monthly_report(user, month: int, year: int) -> dict:
    prev_year, prev_month = _shift_month(year, month, -1)

    current = _month_totals(user, year, month)
    previous_raw = _month_totals(user, prev_year, prev_month)
    has_previous_data = bool(previous_raw["income"] or previous_raw["expense"])
    previous = previous_raw if has_previous_data else None

    if previous is not None:
        change_percent = {
            "income": _percent_change(current["income"], previous["income"]),
            "expense": _percent_change(current["expense"], previous["expense"]),
            "savings": _percent_change(current["savings"], previous["savings"]),
        }
    else:
        change_percent = None

    current_categories = _category_totals(user, year, month)
    previous_categories = _category_totals(user, prev_year, prev_month)

    top_category_increase = None
    best_percent = None
    for name, (prev_total, prev_count) in previous_categories.items():
        if prev_count < 1 or not prev_total:
            continue
        curr_total, curr_count = current_categories.get(name, (Decimal("0"), 0))
        if curr_count < 1:
            continue
        pct = _percent_change(curr_total, prev_total)
        if pct is None or pct < 20:
            continue
        if best_percent is None or pct > best_percent:
            best_percent = pct
            top_category_increase = {"name": name, "percent": pct}

    insights = []
    if top_category_increase is not None:
        insights.append(
            "Bu oy {name}ga o'tgan oyga nisbatan {percent:.1f}% ko'proq sarfladingiz".format(
                name=top_category_increase["name"], percent=top_category_increase["percent"]
            )
        )

    return {
        "current_month": current,
        "previous_month": previous,
        "change_percent": change_percent,
        "top_category_increase": top_category_increase,
        "insights": insights,
    }
