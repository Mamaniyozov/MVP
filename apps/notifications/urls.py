from django.urls import path
from apps.notifications.views import NotificationListView, NotificationMarkAsReadView, DeviceRegisterView

urlpatterns = [
    path("", NotificationListView.as_view(), name="notification-list"),
    path("<int:pk>/read/", NotificationMarkAsReadView.as_view(), name="notification-mark-read"),
    path("device/", DeviceRegisterView.as_view(), name="device-register"),
]
