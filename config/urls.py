from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from config.views import health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", health_check, name="health-check"),
    path("api/v1/auth/", include("apps.users.urls")),
    path("api/v1/", include("apps.categories.urls")),
    path("api/v1/", include("apps.cards.urls")),
    path("api/v1/", include("apps.transactions.urls")),
    path("api/v1/", include("apps.goals.urls")),
    path("api/v1/", include("apps.analytics.urls")),
    path("api/v1/budgets/", include("apps.budgets.urls")),
    path("api/v1/notifications/", include("apps.notifications.urls")),

    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path("", include("django_prometheus.urls")),
]
