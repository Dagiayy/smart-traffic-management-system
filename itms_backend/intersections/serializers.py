"""intersections/serializers.py"""
from rest_framework import serializers
from .models import Intersection, Lane, TrafficCamera, SignalState


class LaneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lane
        fields = ['id', 'direction', 'lane_number', 'lane_type', 'sumo_lane_id']


class CameraSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrafficCamera
        fields = ['id', 'camera_code', 'direction', 'is_active', 'last_heartbeat', 'stream_url']


class SignalStateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SignalState
        fields = ['id', 'phase', 'green_duration', 'source', 'ai_confidence',
                  'activated_at', 'expires_at', 'override_reason']


class IntersectionSerializer(serializers.ModelSerializer):
    current_signal = serializers.SerializerMethodField()

    class Meta:
        model = Intersection
        fields = ['id', 'name', 'latitude', 'longitude', 'city', 'zone',
                  'num_lanes', 'is_active', 'sumo_node_id', 'current_signal']

    def get_current_signal(self, obj):
        latest = obj.signal_states.order_by('-activated_at').first()
        return SignalStateSerializer(latest).data if latest else None


class IntersectionDetailSerializer(IntersectionSerializer):
    lanes = LaneSerializer(many=True, read_only=True)
    cameras = CameraSerializer(many=True, read_only=True)

    class Meta(IntersectionSerializer.Meta):
        fields = IntersectionSerializer.Meta.fields + ['lanes', 'cameras']
