from datetime import date
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.analytics.services import (
    _shift_month,
    get_category_breakdown,
    get_monthly_report,
    get_monthly_trend,
)
from apps.categories.models import Category
from apps.transactions.models import Transaction


@pytest.mark.django_db
def test_category_breakdown_normal():
    user = User.objects.create_user(username="cb1@example.com", email="cb1@example.com", password="Str0ngPass!1")
    food = Category.objects.filter(user=user, type="expense").first()
    transport = Category.objects.filter(user=user, type="expense").exclude(id=food.id).first()
    income_category = Category.objects.filter(user=user, type="income").first()

    Transaction.objects.create(user=user, category=food, amount="700000", type="expense", date="2026-07-05")
    Transaction.objects.create(user=user, category=food, amount="300000", type="expense", date="2026-07-10")
    Transaction.objects.create(user=user, category=transport, amount="500000", type="expense", date="2026-07-15")
    # income should never be counted, regardless of month
    Transaction.objects.create(user=user, category=income_category, amount="5000000", type="income", date="2026-07-01")
    # different month, must be excluded
    Transaction.objects.create(user=user, category=food, amount="999999", type="expense", date="2026-06-01")

    result = get_category_breakdown(user, month=7, year=2026)

    assert result == [
        {"category": food.name, "total": Decimal("1000000"), "percent": 66.67},
        {"category": transport.name, "total": Decimal("500000"), "percent": 33.33},
    ]


@pytest.mark.django_db
def test_category_breakdown_empty_month_returns_empty_list():
    user = User.objects.create_user(username="cb2@example.com", email="cb2@example.com", password="Str0ngPass!1")

    result = get_category_breakdown(user, month=1, year=2020)

    assert result == []


@pytest.mark.django_db
def test_category_breakdown_does_not_leak_other_users_data():
    user = User.objects.create_user(username="cb3@example.com", email="cb3@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="cb4@example.com", email="cb4@example.com", password="Str0ngPass!1")
    own_category = Category.objects.filter(user=user, type="expense").first()
    other_category = Category.objects.filter(user=other, type="expense").first()

    Transaction.objects.create(user=user, category=own_category, amount="100000", type="expense", date="2026-07-01")
    Transaction.objects.create(user=other, category=other_category, amount="9999999", type="expense", date="2026-07-01")

    result = get_category_breakdown(user, month=7, year=2026)

    assert len(result) == 1
    assert result[0]["total"] == Decimal("100000")


@pytest.mark.django_db
def test_monthly_trend_normal_and_missing_months_filled_with_zero():
    user = User.objects.create_user(username="mt1@example.com", email="mt1@example.com", password="Str0ngPass!1")
    income_category = Category.objects.filter(user=user, type="income").first()
    expense_category = Category.objects.filter(user=user, type="expense").first()

    today = date.today()
    y0, m0 = today.year, today.month
    y2, m2 = _shift_month(y0, m0, -2)
    y1, m1 = _shift_month(y0, m0, -1)  # deliberately left with no transactions

    Transaction.objects.create(
        user=user, category=income_category, amount="5000000", type="income", date=date(y0, m0, 1)
    )
    Transaction.objects.create(
        user=user, category=expense_category, amount="3200000", type="expense", date=date(y0, m0, 1)
    )
    Transaction.objects.create(
        user=user, category=income_category, amount="1000000", type="income", date=date(y2, m2, 1)
    )
    Transaction.objects.create(
        user=user, category=expense_category, amount="500000", type="expense", date=date(y2, m2, 1)
    )

    result = get_monthly_trend(user, months=6)

    assert len(result) == 6
    months_list = [row["month"] for row in result]
    assert months_list == sorted(months_list)

    current_row = result[-1]
    assert current_row["month"] == f"{y0:04d}-{m0:02d}"
    assert current_row["income"] == Decimal("5000000")
    assert current_row["expense"] == Decimal("3200000")

    two_months_ago_row = next(row for row in result if row["month"] == f"{y2:04d}-{m2:02d}")
    assert two_months_ago_row["income"] == Decimal("1000000")
    assert two_months_ago_row["expense"] == Decimal("500000")

    one_month_ago_row = next(row for row in result if row["month"] == f"{y1:04d}-{m1:02d}")
    assert one_month_ago_row["income"] == Decimal("0")
    assert one_month_ago_row["expense"] == Decimal("0")


@pytest.mark.django_db
def test_monthly_report_normal_with_previous_month():
    user = User.objects.create_user(username="mr1@example.com", email="mr1@example.com", password="Str0ngPass!1")
    food = Category.objects.filter(user=user, type="expense").first()
    income_category = Category.objects.filter(user=user, type="income").first()

    Transaction.objects.create(user=user, category=income_category, amount="6000000", type="income", date="2026-07-01")
    Transaction.objects.create(user=user, category=food, amount="1200000", type="expense", date="2026-07-05")

    Transaction.objects.create(user=user, category=income_category, amount="5000000", type="income", date="2026-06-01")
    Transaction.objects.create(user=user, category=food, amount="1000000", type="expense", date="2026-06-05")

    report = get_monthly_report(user, month=7, year=2026)

    assert report["current_month"] == {
        "income": Decimal("6000000"),
        "expense": Decimal("1200000"),
        "savings": Decimal("4800000"),
    }
    assert report["previous_month"] == {
        "income": Decimal("5000000"),
        "expense": Decimal("1000000"),
        "savings": Decimal("4000000"),
    }
    assert report["change_percent"] == {"income": 20.0, "expense": 20.0, "savings": 20.0}
    assert report["top_category_increase"] == {"name": food.name, "percent": 20.0}
    assert report["insights"] == [
        f"Bu oy {food.name}ga o'tgan oyga nisbatan 20.0% ko'proq sarfladingiz"
    ]


@pytest.mark.django_db
def test_monthly_report_only_current_month_present():
    user = User.objects.create_user(username="mr2@example.com", email="mr2@example.com", password="Str0ngPass!1")
    food = Category.objects.filter(user=user, type="expense").first()
    income_category = Category.objects.filter(user=user, type="income").first()

    Transaction.objects.create(user=user, category=income_category, amount="4000000", type="income", date="2026-07-10")
    Transaction.objects.create(user=user, category=food, amount="900000", type="expense", date="2026-07-12")

    report = get_monthly_report(user, month=7, year=2026)

    assert report["current_month"] == {
        "income": Decimal("4000000"),
        "expense": Decimal("900000"),
        "savings": Decimal("3100000"),
    }
    assert report["previous_month"] is None
    assert report["change_percent"] is None
    assert report["top_category_increase"] is None
    assert report["insights"] == []


@pytest.mark.django_db
def test_monthly_report_small_category_increase_yields_no_insights():
    user = User.objects.create_user(username="mr3@example.com", email="mr3@example.com", password="Str0ngPass!1")
    food = Category.objects.filter(user=user, type="expense").first()
    income_category = Category.objects.filter(user=user, type="income").first()

    Transaction.objects.create(user=user, category=income_category, amount="5000000", type="income", date="2026-07-01")
    Transaction.objects.create(user=user, category=food, amount="1050000", type="expense", date="2026-07-05")

    Transaction.objects.create(user=user, category=income_category, amount="5000000", type="income", date="2026-06-01")
    Transaction.objects.create(user=user, category=food, amount="1000000", type="expense", date="2026-06-05")

    report = get_monthly_report(user, month=7, year=2026)

    assert report["previous_month"] is not None
    assert report["top_category_increase"] is None
    assert report["insights"] == []


@pytest.mark.django_db
def test_category_breakdown_api_requires_auth_and_returns_data():
    user = User.objects.create_user(username="api1@example.com", email="api1@example.com", password="Str0ngPass!1")
    food = Category.objects.filter(user=user, type="expense").first()
    Transaction.objects.create(user=user, category=food, amount="100000", type="expense", date="2026-07-05")

    client = APIClient()
    unauth_response = client.get("/api/v1/analytics/category-breakdown/", {"month": 7, "year": 2026})
    assert unauth_response.status_code == 401

    client.force_authenticate(user=user)
    response = client.get("/api/v1/analytics/category-breakdown/", {"month": 7, "year": 2026})
    assert response.status_code == 200
    assert response.data[0]["category"] == food.name


@pytest.mark.django_db
def test_category_breakdown_api_invalid_month_returns_400():
    user = User.objects.create_user(username="api4@example.com", email="api4@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/analytics/category-breakdown/", {"month": "abc"})
    assert response.status_code == 400
    assert "month" in response.data

    response = client.get("/api/v1/analytics/category-breakdown/", {"month": 13})
    assert response.status_code == 400
    assert "month" in response.data


@pytest.mark.django_db
def test_monthly_trend_api_invalid_months_returns_400():
    user = User.objects.create_user(username="api5@example.com", email="api5@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/analytics/monthly-trend/", {"months": "abc"})
    assert response.status_code == 400
    assert "months" in response.data

    response = client.get("/api/v1/analytics/monthly-trend/", {"months": 0})
    assert response.status_code == 400
    assert "months" in response.data


@pytest.mark.django_db
def test_monthly_trend_api_default_months():
    user = User.objects.create_user(username="api2@example.com", email="api2@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/analytics/monthly-trend/")

    assert response.status_code == 200
    assert len(response.data) == 6


@pytest.mark.django_db
def test_monthly_report_api_default_month_year():
    user = User.objects.create_user(username="api3@example.com", email="api3@example.com", password="Str0ngPass!1")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/analytics/monthly-report/")

    assert response.status_code == 200
    assert "current_month" in response.data
    assert "insights" in response.data
