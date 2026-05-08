"""vehicles/views.py"""
from rest_framework import generics
from itms_backend.permissions import IsOfficerOrAbove
from .models import Vehicle
from .serializers import VehicleSerializer


class VehicleListView(generics.ListAPIView):
    """Officer/admin — search all vehicles."""
    permission_classes = [IsOfficerOrAbove]
    serializer_class = VehicleSerializer

    def get_queryset(self):
        qs = Vehicle.objects.select_related('owner').order_by('-created_at')
        plate = self.request.query_params.get('plate')
        if plate:
            qs = qs.filter(plate_number__icontains=plate.upper())
        return qs
