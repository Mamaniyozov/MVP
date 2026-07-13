import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from apps.cards.models import Card
from apps.categories.models import Category
from apps.transactions.models import Transaction


@pytest.mark.django_db
def test_create_transaction():
    user = User.objects.create_user(username="t@example.com", email="t@example.com", password="Str0ngPass!1")
    category = Category.objects.filter(user=user, type="expense").first()

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/transactions/",
        {
            "category": category.id,
            "amount": "15000.50",
            "type": "expense",
            "date": "2026-07-13",
            "note": "lunch",
        },
    )

    assert response.status_code == 201
    assert response.data["amount"] == "15000.50"


@pytest.mark.django_db
def test_cannot_use_other_users_category():
    user = User.objects.create_user(username="t2@example.com", email="t2@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="t3@example.com", email="t3@example.com", password="Str0ngPass!1")
    other_category = Category.objects.filter(user=other, type="expense").first()

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/transactions/",
        {
            "category": other_category.id,
            "amount": "1000",
            "type": "expense",
            "date": "2026-07-13",
        },
    )

    assert response.status_code == 400


@pytest.mark.django_db
def test_cannot_use_other_users_card():
    user = User.objects.create_user(username="t4@example.com", email="t4@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="t5@example.com", email="t5@example.com", password="Str0ngPass!1")
    category = Category.objects.filter(user=user, type="expense").first()
    other_card = Card.objects.create(user=other, name="Other's Visa")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(
        "/api/v1/transactions/",
        {
            "category": category.id,
            "card": other_card.id,
            "amount": "1000",
            "type": "expense",
            "date": "2026-07-13",
        },
    )

    assert response.status_code == 400


@pytest.mark.django_db
def test_user_cannot_see_or_modify_other_users_transaction():
    user = User.objects.create_user(username="t6@example.com", email="t6@example.com", password="Str0ngPass!1")
    other = User.objects.create_user(username="t7@example.com", email="t7@example.com", password="Str0ngPass!1")
    other_category = Category.objects.filter(user=other, type="expense").first()
    other_txn = Transaction.objects.create(
        user=other, category=other_category, amount="5000", type="expense", date="2026-07-01"
    )

    client = APIClient()
    client.force_authenticate(user=user)

    detail_url = f"/api/v1/transactions/{other_txn.id}/"

    get_response = client.get(detail_url)
    assert get_response.status_code == 404

    patch_response = client.patch(detail_url, {"amount": "1"})
    assert patch_response.status_code == 404

    delete_response = client.delete(detail_url)
    assert delete_response.status_code == 404

    assert Transaction.objects.filter(id=other_txn.id, amount="5000").exists()


@pytest.mark.django_db
def test_filter_by_date_range_category_and_type():
    user = User.objects.create_user(username="t8@example.com", email="t8@example.com", password="Str0ngPass!1")
    expense_category = Category.objects.filter(user=user, type="expense").first()
    income_category = Category.objects.filter(user=user, type="income").first()

    old_txn = Transaction.objects.create(
        user=user, category=expense_category, amount="1000", type="expense", date="2026-01-01"
    )
    in_range_expense = Transaction.objects.create(
        user=user, category=expense_category, amount="2000", type="expense", date="2026-06-15"
    )
    in_range_income = Transaction.objects.create(
        user=user, category=income_category, amount="3000", type="income", date="2026-06-20"
    )

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get(
        "/api/v1/transactions/",
        {"date_from": "2026-06-01", "date_to": "2026-06-30"},
    )
    assert response.status_code == 200
    ids = {item["id"] for item in response.data["results"]}
    assert ids == {in_range_expense.id, in_range_income.id}
    assert old_txn.id not in ids

    type_response = client.get("/api/v1/transactions/", {"type": "income"})
    type_ids = {item["id"] for item in type_response.data["results"]}
    assert type_ids == {in_range_income.id}

    category_response = client.get("/api/v1/transactions/", {"category": expense_category.id})
    category_ids = {item["id"] for item in category_response.data["results"]}
    assert category_ids == {old_txn.id, in_range_expense.id}


@pytest.mark.django_db
def test_ordering_by_amount():
    user = User.objects.create_user(username="t9@example.com", email="t9@example.com", password="Str0ngPass!1")
    category = Category.objects.filter(user=user, type="expense").first()

    Transaction.objects.create(user=user, category=category, amount="500", type="expense", date="2026-01-01")
    Transaction.objects.create(user=user, category=category, amount="100", type="expense", date="2026-01-02")
    Transaction.objects.create(user=user, category=category, amount="900", type="expense", date="2026-01-03")

    client = APIClient()
    client.force_authenticate(user=user)

    response = client.get("/api/v1/transactions/", {"ordering": "amount"})
    amounts = [item["amount"] for item in response.data["results"]]
    assert amounts == ["100.00", "500.00", "900.00"]
