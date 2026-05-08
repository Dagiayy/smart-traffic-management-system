"""
ai_brain/views.py
Endpoints called BY the AI Brain Python service (SUMO + RL + CV).
Authenticated with X-AI-Service-Key header.
"""
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from itms_backend.permissions import IsAIService
from intersections.models import Intersection, SignalState
from intersections.serializers import IntersectionDetailSerializer
from vehicles.models import Vehicle
from violations.models import Violation, ViolationType, ViolationEvidence
from violations.officer_views import _create_fine_for_violation, _broadcast_new_violation
from .models import (
    AISession, RLEpisode, SignalDecision,
    CongestedZone, AIAlert, SimulationLog,
)
from .serializers import CongestedZoneSerializer, AIAlertSerializer


class AIIntersectionStateView(APIView):
    """AI fetches current state of all intersections."""
    permission_classes = [IsAIService]

    def get(self, request):
        intersections = Intersection.objects.filter(is_active=True).prefetch_related(
            'lanes', 'cameras', 'signal_states'
        )
        data = []
        for i in intersections:
            latest_signal = i.signal_states.order_by('-activated_at').first()
            data.append({
                'id': str(i.id),
                'name': i.name,
                'sumo_node_id': i.sumo_node_id,
                'latitude': float(i.latitude),
                'longitude': float(i.longitude),
                'num_lanes': i.num_lanes,
                'current_phase': latest_signal.phase if latest_signal else 'NS_GREEN',
                'green_duration': latest_signal.green_duration if latest_signal else 30,
                'source': latest_signal.source if latest_signal else 'FIXED_TIMER',
                # Queue lengths would come from SUMO TraCI in real deployment
                'queue_lengths': {},
                'waiting_times': {},
                'pedestrian_counts': {},
            })
        return Response({'count': len(data), 'intersections': data})


class AISignalDecisionView(APIView):
    """AI posts optimized signal decision."""
    permission_classes = [IsAIService]

    def post(self, request):
        intersection_id = request.data.get('intersection_id')
        phase = request.data.get('phase', 'NS_GREEN')
        duration = request.data.get('duration_seconds', 30)
        confidence = request.data.get('confidence', 0.0)
        episode_id = request.data.get('episode_id')
        session_id = request.data.get('session_id')

        try:
            intersection = Intersection.objects.get(pk=intersection_id)
        except Intersection.DoesNotExist:
            return Response({'error': 'Intersection not found.'}, status=404)

        session = None
        if session_id:
            session = AISession.objects.filter(pk=session_id).first()

        episode = None
        if episode_id:
            episode = RLEpisode.objects.filter(pk=episode_id).first()

        # Record the decision
        decision = SignalDecision.objects.create(
            intersection=intersection,
            session=session,
            episode=episode,
            phase=phase,
            duration_seconds=duration,
            confidence=confidence,
        )

        # Update the intersection's signal state
        signal = SignalState.objects.create(
            intersection=intersection,
            phase=phase,
            green_duration=duration,
            source='AI',
            ai_confidence=confidence,
        )

        # Broadcast to admin panel via WebSocket
        from intersections.admin_views import _broadcast_signal_update
        _broadcast_signal_update(intersection, signal)

        return Response({'message': 'Signal decision recorded.', 'decision_id': str(decision.id)})


class AICVDetectionView(APIView):
    """Computer Vision posts detected violation."""
    permission_classes = [IsAIService]

    def post(self, request):
        plate = (request.data.get('plate_number') or '').upper().strip()
        type_code = request.data.get('violation_type_code', '')
        intersection_id = request.data.get('intersection_id')
        camera_id = request.data.get('camera_id')
        evidence_url = request.data.get('evidence_url', '')
        confidence = request.data.get('confidence', 0.0)
        session_id = request.data.get('session_id')

        if not plate or not type_code:
            return Response({'error': 'plate_number and violation_type_code required.'}, status=400)

        # Get or create vehicle
        vehicle, _ = Vehicle.objects.get_or_create(plate_number=plate, defaults={'vehicle_type': 'CAR'})

        # Get violation type
        try:
            vtype = ViolationType.objects.get(code=type_code, is_active=True)
        except ViolationType.DoesNotExist:
            return Response({'error': f'Unknown violation type code: {type_code}'}, status=400)

        # Get intersection
        intersection = None
        if intersection_id:
            intersection = Intersection.objects.filter(pk=intersection_id).first()

        # Create violation
        violation = Violation.objects.create(
            violation_type=vtype,
            vehicle=vehicle,
            intersection=intersection,
            source='AI_DETECTION',
            status='DETECTED',
            severity=vtype.default_severity,
            ai_confidence=confidence,
            detected_at=timezone.now(),
        )

        # Attach evidence URL
        if evidence_url:
            ViolationEvidence.objects.create(
                violation=violation,
                file_url=evidence_url,
                file_type='IMAGE',
                source='CAMERA',
            )

        # Auto-create fine
        _create_fine_for_violation(violation)

        # Notify admin panel
        _broadcast_new_violation(violation)

        # Notify vehicle owner
        if vehicle.owner:
            from notifications.models import Notification
            Notification.objects.create(
                user=vehicle.owner,
                title='New Violation Detected',
                message=f'A {vtype.name} violation was detected for your vehicle {plate}.',
                notification_type='VIOLATION_DETECTED',
            )

        return Response({
            'violation_id': str(violation.id),
            'message': 'Violation recorded.',
            'status': 'DETECTED',
        }, status=status.HTTP_201_CREATED)


class AICongestionAlertView(APIView):
    """AI posts congestion zone detection."""
    permission_classes = [IsAIService]

    def post(self, request):
        intersection_id = request.data.get('intersection_id')
        severity = request.data.get('severity', 'MEDIUM')
        delay = request.data.get('estimated_delay', 0)
        affected_lanes = request.data.get('affected_lanes', [])

        try:
            intersection = Intersection.objects.get(pk=intersection_id)
        except Intersection.DoesNotExist:
            return Response({'error': 'Intersection not found.'}, status=404)

        # Mark any previous congestion as resolved
        CongestedZone.objects.filter(
            intersection=intersection, resolved_at__isnull=True
        ).update(resolved_at=timezone.now())

        zone = CongestedZone.objects.create(
            intersection=intersection,
            severity=severity,
            affected_lanes=affected_lanes,
            estimated_delay_seconds=delay,
        )

        # Create alert
        AIAlert.objects.create(
            alert_type='CONGESTION',
            severity='CRITICAL' if severity in ('HIGH', 'CRITICAL') else 'WARNING',
            message=f'Congestion detected near {intersection.name}. Severity: {severity}. Delay: {delay}s.',
            intersection=intersection,
            metadata={'zone_id': str(zone.id)},
        )

        # Broadcast alert
        _broadcast_alert({'type': 'CONGESTION', 'message': f'Congestion near {intersection.name}', 'severity': severity})

        return Response({'zone_id': str(zone.id), 'message': 'Congestion recorded.'})


class AIEpisodeLogView(APIView):
    """Log RL episode results."""
    permission_classes = [IsAIService]

    def post(self, request):
        session_id = request.data.get('session_id')
        episode_num = request.data.get('episode_num', 0)
        total_reward = request.data.get('total_reward', 0)
        avg_wait = request.data.get('avg_wait', 0)
        steps = request.data.get('steps', 0)
        epsilon = request.data.get('epsilon', 1.0)
        loss = request.data.get('loss')

        session = AISession.objects.filter(pk=session_id).first()
        if not session:
            return Response({'error': 'Session not found.'}, status=404)

        episode = RLEpisode.objects.create(
            session=session,
            episode_number=episode_num,
            total_reward=total_reward,
            avg_waiting_time=avg_wait,
            throughput=steps,
            epsilon=epsilon,
            loss=loss,
        )

        # Broadcast to dev panel via WebSocket
        _broadcast_training_update(session, episode)

        return Response({'episode_id': str(episode.id), 'message': 'Episode logged.'})


class AISimulationLogView(APIView):
    """Post simulation log entry."""
    permission_classes = [IsAIService]

    def post(self, request):
        session_id = request.data.get('session_id')
        level = request.data.get('level', 'INFO')
        message = request.data.get('message', '')
        metadata = request.data.get('metadata', {})

        session = AISession.objects.filter(pk=session_id).first()

        SimulationLog.objects.create(
            session=session,
            level=level,
            message=message,
            metadata=metadata,
        )
        return Response({'message': 'Log recorded.'})


class AIConfigView(APIView):
    """AI fetches its current configuration from Django."""
    permission_classes = [IsAIService]

    def get(self, request):
        from django.conf import settings
        # Get the latest active session's params
        session = AISession.objects.filter(status='RUNNING').order_by('-started_at').first()
        rl_params = session.rl_params if session else {
            'learning_rate': 0.001,
            'gamma': 0.99,
            'epsilon': 1.0,
            'epsilon_decay': 0.995,
            'epsilon_min': 0.01,
            'batch_size': 32,
            'memory_size': 10000,
        }
        return Response({
            'session_id': str(session.id) if session else None,
            'rl_params': rl_params,
            'active_intersections': list(
                Intersection.objects.filter(is_active=True).values('id', 'name', 'sumo_node_id')
            ),
            'system_flags': {
                'cv_enabled': True,
                'rl_enabled': True,
                'sumo_connected': True,
            }
        })


# ── Broadcast helpers ─────────────────────────────────────────────────────
def _broadcast_alert(data):
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)('alerts', {
            'type': 'alert_message', 'data': data
        })
    except Exception:
        pass


def _broadcast_training_update(session, episode):
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'ai_session_{session.id}',
            {
                'type': 'training_update',
                'data': {
                    'session_id': str(session.id),
                    'episode': episode.episode_number,
                    'reward': float(episode.total_reward),
                    'epsilon': float(episode.epsilon),
                    'avg_wait': float(episode.avg_waiting_time),
                    'loss': float(episode.loss) if episode.loss else None,
                }
            }
        )
    except Exception:
        pass
