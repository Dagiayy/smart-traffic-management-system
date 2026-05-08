"""violations/admin_views.py"""
from django.db.models import Count, Q
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from itms_backend.permissions import IsAdminOrDeveloper, IsAdmin
from .models import Violation, ViolationEvidence, ViolationStatusHistory, ViolationType
from .serializers import ViolationSerializer, EvidenceSerializer


class AdminViolationsListView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = ViolationSerializer

    def get_queryset(self):
        qs = Violation.objects.select_related(
            'violation_type', 'vehicle', 'intersection', 'officer'
        ).prefetch_related('evidence_files')

        for param, field in [
            ('status', 'status'), ('severity', 'severity'),
            ('source', 'source'), ('type', 'violation_type__code'),
            ('intersection', 'intersection__id'),
        ]:
            v = self.request.query_params.get(param)
            if v:
                qs = qs.filter(**{field: v})

        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            qs = qs.filter(detected_at__date__gte=date_from)
        if date_to:
            qs = qs.filter(detected_at__date__lte=date_to)

        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(Q(vehicle__plate_number__icontains=search) | Q(officer__full_name__icontains=search))

        return qs.order_by('-detected_at')


class AdminViolationDetailView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request, pk):
        try:
            violation = Violation.objects.select_related(
                'violation_type', 'vehicle', 'intersection', 'officer'
            ).prefetch_related('evidence_files', 'status_history').get(pk=pk)
        except Violation.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)

        data = ViolationSerializer(violation, context={'request': request}).data
        # Include status history
        data['status_history'] = [
            {
                'from': h.old_status, 'to': h.new_status,
                'by': h.changed_by.full_name if h.changed_by else 'System',
                'reason': h.reason,
                'at': h.changed_at.isoformat(),
            }
            for h in violation.status_history.order_by('-changed_at')
        ]
        # Include linked fine
        try:
            fine = violation.fine
            data['fine'] = {'id': str(fine.id), 'amount': str(fine.amount), 'status': fine.status}
        except Exception:
            data['fine'] = None
        # Include dispute
        try:
            dispute = violation.disputes.first()
            data['dispute'] = {'id': str(dispute.id), 'status': dispute.status} if dispute else None
        except Exception:
            data['dispute'] = None
        return Response(data)

    def patch(self, request, pk):
        try:
            violation = Violation.objects.get(pk=pk)
        except Violation.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)

        old_status = violation.status
        new_status = request.data.get('status', violation.status)
        admin_notes = request.data.get('admin_notes', '')

        violation.status = new_status
        if admin_notes:
            violation.notes = f'{violation.notes}\n[Admin: {admin_notes}]'.strip()
        violation.save()

        if old_status != new_status:
            ViolationStatusHistory.objects.create(
                violation=violation, old_status=old_status,
                new_status=new_status, changed_by=request.user, reason=admin_notes
            )

        return Response(ViolationSerializer(violation).data)


class AdminEvidenceListView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = EvidenceSerializer
    queryset = ViolationEvidence.objects.select_related('violation').order_by('-uploaded_at')


class AdminEvidenceDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = EvidenceSerializer
    queryset = ViolationEvidence.objects.all()


class AdminHotspotMapView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from django.utils import timezone
        from datetime import timedelta
        period = request.query_params.get('period', 'week')
        start = {
            'day': timezone.now() - timedelta(days=1),
            'week': timezone.now() - timedelta(days=7),
            'month': timezone.now() - timedelta(days=30),
        }.get(period, timezone.now() - timedelta(days=7))

        qs = Violation.objects.filter(
            detected_at__gte=start, intersection__isnull=False
        ).values(
            'intersection__id', 'intersection__name',
            'intersection__latitude', 'intersection__longitude'
        ).annotate(count=Count('id')).order_by('-count')[:30]

        return Response({
            'results': [{
                'id': r['intersection__id'],
                'name': r['intersection__name'],
                'lat': float(r['intersection__latitude']),
                'lng': float(r['intersection__longitude']),
                'count': r['count'],
                'severity': 'CRITICAL' if r['count'] > 20 else ('MAJOR' if r['count'] > 10 else 'MINOR'),
            } for r in qs]
        })
