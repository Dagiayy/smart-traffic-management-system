from django.urls import path
from rest_framework import generics
from itms_backend.permissions import IsOfficerOrAbove
from .models import Intersection
from .serializers import IntersectionSerializer


class IntersectionsListView(generics.ListAPIView):
    permission_classes = [IsOfficerOrAbove]
    serializer_class = IntersectionSerializer

    def get_queryset(self):
        qs = Intersection.objects.filter(is_active=True)
        lat = self.request.query_params.get('lat')
        lng = self.request.query_params.get('lng')
        # TODO: order by distance if lat/lng provided
        return qs.order_by('name')[:50]


urlpatterns = [
    # Officer: get nearby intersections for ticket location
    path('officer/intersections/', IntersectionsListView.as_view()),
]
