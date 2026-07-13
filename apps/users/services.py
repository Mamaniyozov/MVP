from apps.categories.models import Category
from apps.users.models import UserProfile

DEFAULT_EXPENSE_CATEGORIES = [
    ("Oziq-ovqat", "utensils"),
    ("Transport", "car"),
    ("Kommunal to'lovlar", "receipt"),
    ("Ko'ngilochar", "smile"),
    ("To'y/marosim", "gift"),
    ("Qarindoshlarga yordam", "heart"),
    ("Sog'liq", "activity"),
    ("Ta'lim", "book"),
    ("Boshqa", "more-horizontal"),
]

DEFAULT_INCOME_CATEGORIES = [
    ("Maosh", "briefcase"),
    ("Boshqa daromad", "plus-circle"),
]


def create_user_profile(user):
    UserProfile.objects.get_or_create(user=user)


def create_default_categories(user):
    categories = [
        Category(user=user, name=name, type="expense", icon=icon, is_default=True)
        for name, icon in DEFAULT_EXPENSE_CATEGORIES
    ] + [
        Category(user=user, name=name, type="income", icon=icon, is_default=True)
        for name, icon in DEFAULT_INCOME_CATEGORIES
    ]
    Category.objects.bulk_create(categories)
