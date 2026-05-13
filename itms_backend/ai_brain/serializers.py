"""ai_brain/serializers.py"""
from rest_framework import serializers
from .models import AISession, RLEpisode, SignalDecision, CongestedZone, AIAlert, ExperimentConfig, SimulationLog


class RLEpisodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = RLEpisode
        fields = ['id', 'episode_number', 'total_reward', 'avg_waiting_time',
                  'throughput', 'pedestrian_delay', 'epsilon', 'loss', 'recorded_at']


class AISessionSerializer(serializers.ModelSerializer):
    total_episodes = serializers.IntegerField(read_only=True)
    latest_avg_reward = serializers.FloatField(read_only=True)
    started_by_name = serializers.CharField(source='started_by.full_name', read_only=True, default=None)

    class Meta:
        model = AISession
        fields = ['id', 'name', 'scenario_id', 'status', 'rl_params',
                  'started_at', 'ended_at', 'started_by_name',
                  'total_episodes', 'latest_avg_reward']


class AISessionDetailSerializer(AISessionSerializer):
    episodes = RLEpisodeSerializer(many=True, read_only=True)

    class Meta(AISessionSerializer.Meta):
        fields = AISessionSerializer.Meta.fields + ['episodes']


class SignalDecisionSerializer(serializers.ModelSerializer):
    intersection_name = serializers.CharField(source='intersection.name', read_only=True)

    class Meta:
        model = SignalDecision
        fields = ['id', 'intersection_name', 'phase', 'duration_seconds',
                  'confidence', 'decided_at']


class CongestedZoneSerializer(serializers.ModelSerializer):
    intersection_name = serializers.CharField(source='intersection.name', read_only=True)
    lat = serializers.FloatField(source='intersection.lat', read_only=True)
    lng = serializers.FloatField(source='intersection.lng', read_only=True)
    # For citizen alerts compat
    title = serializers.CharField(source='intersection.name', read_only=True)
    message = serializers.SerializerMethodField()
    type = serializers.CharField(default='CONGESTION', read_only=True)
    location_name = serializers.CharField(source='intersection.name', read_only=True)
    created_at = serializers.DateTimeField(source='detected_at', read_only=True)
    is_active = serializers.SerializerMethodField()

    class Meta:
        model = CongestedZone
        fields = ['id', 'intersection_name', 'lat', 'lng', 'severity',
                  'affected_lanes', 'estimated_delay_seconds',
                  'detected_at', 'resolved_at', 'title', 'message', 'type',
                  'location_name', 'created_at', 'is_active']

    def get_message(self, obj):
        return f'Heavy congestion near {obj.intersection.name}. Estimated delay: {obj.estimated_delay_seconds}s.'

    def get_is_active(self, obj):
        return obj.resolved_at is None


class AIAlertSerializer(serializers.ModelSerializer):
    intersection_name = serializers.CharField(source='intersection.name', read_only=True, default=None)

    class Meta:
        model = AIAlert
        fields = ['id', 'alert_type', 'severity', 'message',
                  'intersection_name', 'metadata', 'created_at', 'resolved_at']


class ExperimentConfigSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True, default=None)

    class Meta:
        model = ExperimentConfig
        fields = ['id', 'name', 'description', 'rl_params', 'sumo_scenario',
                  'created_by_name', 'created_at']


class SimulationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SimulationLog
        fields = ['id', 'session', 'level', 'message', 'metadata', 'created_at']
