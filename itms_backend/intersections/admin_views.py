"""intersections/admin_views.py"""
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from itms_backend.permissions import IsAdmin, IsAdminOrDeveloper
from .models import Intersection, SignalState
from .serializers import IntersectionSerializer, IntersectionDetailSerializer, SignalStateSerializer


class AdminIntersectionsListView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = IntersectionSerializer
    queryset = Intersection.objects.all().order_by('name')
    filterset_fields = ['is_active', 'city', 'zone']


class AdminIntersectionDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = IntersectionDetailSerializer
    queryset = Intersection.objects.prefetch_related('lanes', 'cameras', 'signal_states')


class AdminManualOverrideView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request, pk):
        try:
            intersection = Intersection.objects.get(pk=pk)
        except Intersection.DoesNotExist:
            return Response({'error': 'Intersection not found.'}, status=404)

        phase = request.data.get('phase', 'NS_GREEN')
        duration = request.data.get('duration_seconds', 60)
        reason = request.data.get('reason', 'Admin override')

        signal = SignalState.objects.create(
            intersection=intersection,
            phase=phase,
            green_duration=duration,
            source='ADMIN_OVERRIDE',
            expires_at=timezone.now() + timezone.timedelta(seconds=duration),
            override_reason=reason,
            overridden_by=request.user,
        )

        # Broadcast via WebSocket
        _broadcast_signal_update(intersection, signal)

        return Response({
            'message': f'Signal at {intersection.name} overridden.',
            'signal': SignalStateSerializer(signal).data,
        })

    def delete(self, request, pk):
        try:
            intersection = Intersection.objects.get(pk=pk)
        except Intersection.DoesNotExist:
            return Response({'error': 'Intersection not found.'}, status=404)

        # Remove override — create a new AI/fixed state
        signal = SignalState.objects.create(
            intersection=intersection,
            phase='NS_GREEN',
            green_duration=30,
            source='AI',
            override_reason='Override released by admin',
        )
        _broadcast_signal_update(intersection, signal)
        return Response({'message': 'Override released. AI control restored.'})


def _broadcast_signal_update(intersection, signal):
    try:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'traffic_{intersection.id}',
            {
                'type': 'signal_update',
                'data': {
                    'intersection_id': str(intersection.id),
                    'phase': signal.phase,
                    'duration': signal.green_duration,
                    'source': signal.source,
                    'activated_at': signal.activated_at.isoformat(),
                }
            }
        )
    except Exception:
        pass  # Channel layer unavailable in dev
