from django.urls import path

from apps.analytics.views import CategoryBreakdownView, MonthlyReportView, MonthlyTrendView

urlpatterns = [
    path("analytics/category-breakdown/", CategoryBreakdownView.as_view(), name="analytics-category-breakdown"),
    path("analytics/monthly-trend/", MonthlyTrendView.as_view(), name="analytics-monthly-trend"),
    path("analytics/monthly-report/", MonthlyReportView.as_view(), name="analytics-monthly-report"),
]
