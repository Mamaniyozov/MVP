from rest_framework.routers import DefaultRouter

from apps.cards.views import CardViewSet

router = DefaultRouter()
router.register("cards", CardViewSet, basename="card")

urlpatterns = router.urls
