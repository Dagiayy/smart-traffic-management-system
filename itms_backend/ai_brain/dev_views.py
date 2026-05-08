"""ai_brain/dev_views.py — Developer panel endpoints"""
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from itms_backend.permissions import IsAdminOrDeveloper
from .models import AISession, RLEpisode, ExperimentConfig, SimulationLog, SignalDecision
from .serializers import (
    AISessionSerializer, AISessionDetailSerializer, RLEpisodeSerializer,
    ExperimentConfigSerializer, SimulationLogSerializer, SignalDecisionSerializer,
)


class DevAISessionsView(generics.ListCreateAPIView):
    permission_classes = [IsAdminOrDeveloper]

    def get_serializer_class(self):
        return AISessionSerializer

    def get_queryset(self):
        return AISession.objects.all().order_by('-started_at')

    def create(self, request, *args, **kwargs):
        config = request.data.get('config', {})
        scenario_id = request.data.get('scenario_id', 'default')
        name = request.data.get('name', f'Session {timezone.now().strftime("%Y%m%d-%H%M%S")}')

        # Stop any currently running sessions
        AISession.objects.filter(status='RUNNING').update(
            status='STOPPED', ended_at=timezone.now()
        )

        session = AISession.objects.create(
            name=name,
            scenario_id=scenario_id,
            status='RUNNING',
            rl_params=config,
            started_by=request.user,
        )
        # Signal AI brain (in prod, this would call the AI service)
        return Response(AISessionSerializer(session).data, status=201)


class DevAISessionDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = AISessionDetailSerializer
    queryset = AISession.objects.all()


class DevStopSessionView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def post(self, request, pk):
        try:
            session = AISession.objects.get(pk=pk)
        except AISession.DoesNotExist:
            return Response({'error': 'Session not found.'}, status=404)
        session.status = 'STOPPED'
        session.ended_at = timezone.now()
        session.save()
        return Response({'message': 'Session stopped.', 'status': 'STOPPED'})


class DevSessionEpisodesView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = RLEpisodeSerializer

    def get_queryset(self):
        return RLEpisode.objects.filter(session_id=self.kwargs['pk']).order_by('episode_number')


class DevExperimentsView(generics.ListCreateAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = ExperimentConfigSerializer
    queryset = ExperimentConfig.objects.all()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class DevScenariosView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        # Return list of available SUMO scenarios
        scenarios = [
            {'id': 'addis_bole', 'name': 'Bole Road Corridor', 'duration': 3600, 'intersections': 5},
            {'id': 'addis_mexico', 'name': 'Mexico Square', 'duration': 1800, 'intersections': 1},
            {'id': 'addis_ring', 'name': 'Ring Road Segment', 'duration': 7200, 'intersections': 8},
            {'id': 'training_simple', 'name': 'Simple Training Grid', 'duration': 1800, 'intersections': 2},
        ]
        return Response({'count': len(scenarios), 'results': scenarios})


class DevScenarioReplayView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request, pk):
        # Return step-by-step signal decisions for the scenario
        decisions = SignalDecision.objects.filter(
            session__scenario_id=pk
        ).select_related('intersection').order_by('decided_at')[:500]
        return Response({
            'scenario_id': pk,
            'steps': SignalDecisionSerializer(decisions, many=True).data,
        })


class DevSystemLogsView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = SimulationLogSerializer

    def get_queryset(self):
        qs = SimulationLog.objects.all().order_by('-created_at')
        level = self.request.query_params.get('level')
        session_id = self.request.query_params.get('session_id')
        if level:
            qs = qs.filter(level=level)
        if session_id:
            qs = qs.filter(session_id=session_id)
        return qs


class DevPerformanceComparisonView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        # Compare RL vs fixed timing across sessions
        sessions = AISession.objects.filter(status='COMPLETED').order_by('-started_at')[:10]
        comparison = []
        for s in sessions:
            episodes = s.episodes.all()
            if episodes.exists():
                from django.db.models import Avg
                avg = episodes.aggregate(
                    avg_reward=Avg('total_reward'),
                    avg_wait=Avg('avg_waiting_time'),
                    avg_throughput=Avg('throughput'),
                )
                comparison.append({
                    'session_id': str(s.id),
                    'session_name': s.name,
                    'episodes': episodes.count(),
                    'avg_reward': float(avg['avg_reward'] or 0),
                    'avg_wait_time': float(avg['avg_wait'] or 0),
                    'avg_throughput': float(avg['avg_throughput'] or 0),
                    'rl_params': s.rl_params,
                })
        return Response({'results': comparison})


class DevRLParamsView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def put(self, request):
        """Update live RL hyperparameters for running session."""
        session = AISession.objects.filter(status='RUNNING').order_by('-started_at').first()
        if not session:
            return Response({'error': 'No active session.'}, status=400)

        params = request.data
        session.rl_params.update(params)
        session.save(update_fields=['rl_params'])

        # In production, signal the AI process to pick up new params
        return Response({
            'message': 'Parameters updated.',
            'session_id': str(session.id),
            'rl_params': session.rl_params,
        })
