from django.db.models import Q
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated

from apps.categories.models import Category
from apps.categories.serializers import CategorySerializer


class CategoryViewSet(viewsets.ModelViewSet):
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ["type"]

    def get_queryset(self):
        return Category.objects.filter(Q(user__isnull=True) | Q(user=self.request.user))

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def perform_update(self, serializer):
        # user_id is None — global standart; is_default=True — signup'da yaratilgan
        # (apps/users/services.py) shaxsiy standart kategoriya. Ikkalasi ham himoyalanadi.
        if serializer.instance.user_id is None or serializer.instance.is_default:
            raise PermissionDenied("Standart kategoriyalarni tahrirlab bo'lmaydi.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.user_id is None or instance.is_default:
            raise PermissionDenied("Standart kategoriyalarni o'chirib bo'lmaydi.")
        instance.delete()
