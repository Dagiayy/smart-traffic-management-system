from rest_framework import serializers
from .models import Dispute, DisputeDecision, DisputeEvidence


class DisputeDecisionSerializer(serializers.ModelSerializer):
    decided_by_name = serializers.CharField(source='decided_by.full_name', read_only=True, default=None)
    class Meta:
        model = DisputeDecision
        fields = ['decision', 'reason', 'decided_at', 'decided_by_name']


class DisputeSerializer(serializers.ModelSerializer):
    decision = DisputeDecisionSerializer(read_only=True)
    violation_ref = serializers.CharField(source='violation.id', read_only=True)

    class Meta:
        model = Dispute
        fields = ['id', 'violation', 'violation_ref', 'reason', 'description',
                  'status', 'submitted_at', 'resolved_at', 'decision']
        read_only_fields = ['id', 'status', 'submitted_at', 'resolved_at', 'decision']


class CreateDisputeSerializer(serializers.ModelSerializer):
    violation_id = serializers.UUIDField(write_only=True)

    class Meta:
        model = Dispute
        fields = ['violation_id', 'reason', 'description']

    def validate_violation_id(self, v):
        from violations.models import Violation
        try:
            Violation.objects.get(pk=v)
        except Violation.DoesNotExist:
            raise serializers.ValidationError('Violation not found.')
        return v

    def create(self, validated_data):
        from violations.models import Violation
        violation = Violation.objects.get(pk=validated_data.pop('violation_id'))
        return Dispute.objects.create(violation=violation, **validated_data)


class DisputeDetailSerializer(DisputeSerializer):
    citizen_name = serializers.CharField(source='citizen.full_name', read_only=True)
    violation_plate = serializers.CharField(source='violation.vehicle.plate_number', read_only=True)
    violation_type = serializers.CharField(source='violation.violation_type.name', read_only=True)

    class Meta(DisputeSerializer.Meta):
        fields = DisputeSerializer.Meta.fields + ['citizen_name', 'violation_plate', 'violation_type']
