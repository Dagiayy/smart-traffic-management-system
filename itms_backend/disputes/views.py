"""disputes/views.py — Dispute views (citizen side via accounts/citizen_views.py)"""
# Citizen dispute endpoints live in accounts/citizen_views.py
# Admin dispute endpoints live in accounts/admin_views.py
# This file is intentionally minimal — all logic is co-located near its consumers.

from rest_framework import generics
from itms_backend.permissions import IsAdmin, IsAdminOrDeveloper
from .models import Dispute
from .serializers import DisputeDetailSerializer


class DisputeListView(generics.ListAPIView):
    """Full dispute list for admin/supervisor — also exposed via accounts/admin_urls.py"""
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = DisputeDetailSerializer

    def get_queryset(self):
        qs = Dispute.objects.select_related(
            'violation__violation_type', 'citizen', 'decision'
        ).order_by('-submitted_at')
        status_f = self.request.query_params.get('status')
        if status_f:
            qs = qs.filter(status=status_f)
        return qs
