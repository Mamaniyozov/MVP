from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.budgets.models import Budget
from apps.categories.models import Category
from apps.transactions.models import Transaction


@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def user():
    return User.objects.create_user(
        username="budget_user@example.com", email="budget_user@example.com", password="Pass123!Password"
    )


@pytest.fixture
def other_user():
    return User.objects.create_user(
        username="other_budget@example.com", email="other_budget@example.com", password="Pass123!Password"
    )


@pytest.fixture
def category(user):
    return Category.objects.create(name="Restoran", type="expense", user=user)


@pytest.mark.django_db
def test_create_budget_success(client, user, category):
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/budgets/",
        {
            "category_id": category.id,
            "amount_limit": "2000000.00",
            "month": 7,
            "year": 2026,
        },
    )

    assert response.status_code == 201
    assert response.data["amount_limit"] == "2000000.00"
    assert response.data["spent_amount"] == Decimal("0")
    assert response.data["remaining_amount"] == Decimal("2000000.00")
    assert response.data["is_exceeded"] is False


@pytest.mark.django_db
def test_budget_spent_calculation_and_exceeded_flag(client, user, category):
    client.force_authenticate(user=user)
    budget = Budget.objects.create(
        user=user, category=category, amount_limit=Decimal("100000.00"), month=7, year=2026
    )

    # Add expense transaction in July 2026
    Transaction.objects.create(
        user=user,
        category=category,
        amount=Decimal("120000.00"),
        type="expense",
        date="2026-07-15",
    )

    response = client.get(f"/api/v1/budgets/{budget.id}/")

    assert response.status_code == 200
    assert Decimal(str(response.data["spent_amount"])) == Decimal("120000.00")
    assert Decimal(str(response.data["spent_percent"])) == Decimal("120.0")
    assert response.data["is_exceeded"] is True


@pytest.mark.django_db
def test_budget_cross_user_isolation(client, user, other_user, category):
    budget = Budget.objects.create(
        user=user, category=category, amount_limit=Decimal("500000.00"), month=7, year=2026
    )
    client.force_authenticate(user=other_user)

    response = client.get(f"/api/v1/budgets/{budget.id}/")

    assert response.status_code == 404
