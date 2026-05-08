from rest_framework import serializers
from .models import Violation, ViolationType, ViolationEvidence, ViolationStatusHistory
from fines.models import FineRule


class ViolationTypeSerializer(serializers.ModelSerializer):
    default_fine_amount = serializers.SerializerMethodField()

    class Meta:
        model = ViolationType
        fields = ['id', 'code', 'name', 'description', 'default_severity',
                  'points_deducted', 'legal_reference', 'is_active', 'default_fine_amount']

    def get_default_fine_amount(self, obj):
        rule = FineRule.objects.filter(
            violation_type=obj, severity=obj.default_severity, is_active=True
        ).order_by('-effective_from').first()
        return float(rule.amount) if rule else 0


class EvidenceSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = ViolationEvidence
        fields = ['id', 'file_url', 'file_type', 'source', 'uploaded_at']

    def get_file_url(self, obj):
        if obj.file_url:
            return obj.file_url
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return None


class ViolationSerializer(serializers.ModelSerializer):
    violation_type_name = serializers.CharField(source='violation_type.name', read_only=True)
    type_code = serializers.CharField(source='violation_type.code', read_only=True)
    plate_number = serializers.CharField(source='vehicle.plate_number', read_only=True)
    location_name = serializers.CharField(source='intersection.name', read_only=True, default=None)
    fine_amount = serializers.SerializerMethodField()
    evidence = EvidenceSerializer(source='evidence_files', many=True, read_only=True)
    violation_type = ViolationTypeSerializer(read_only=True)
    officer_name = serializers.CharField(source='officer.full_name', read_only=True, default=None)

    class Meta:
        model = Violation
        fields = [
            'id', 'violation_type', 'violation_type_name', 'type_code',
            'plate_number', 'location_name', 'source', 'status', 'severity',
            'latitude', 'longitude', 'detected_speed', 'ai_confidence',
            'notes', 'driver_name', 'driver_license', 'vehicle_color',
            'fine_amount', 'evidence', 'officer_name',
            'detected_at', 'created_at', 'updated_at',
        ]

    def get_fine_amount(self, obj):
        from fines.models import FineRule
        rule = FineRule.objects.filter(
            violation_type=obj.violation_type,
            severity=obj.severity,
            is_active=True
        ).order_by('-effective_from').first()
        return float(rule.amount) if rule else 0


class ViolationSummarySerializer(serializers.Serializer):
    total_unpaid = serializers.DecimalField(max_digits=12, decimal_places=2)
    active_violations = serializers.IntegerField()
    compliance_score = serializers.IntegerField()
    driver_status = serializers.CharField()


class CreateTicketSerializer(serializers.Serializer):
    plate_number = serializers.CharField(max_length=20)
    violation_type_id = serializers.UUIDField()
    severity = serializers.ChoiceField(choices=['MINOR', 'MAJOR', 'CRITICAL'], required=False)
    location_lat = serializers.FloatField(required=False)
    location_lng = serializers.FloatField(required=False)
    intersection_id = serializers.UUIDField(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)
    driver_name = serializers.CharField(required=False, allow_blank=True)
    driver_license = serializers.CharField(required=False, allow_blank=True)
    vehicle_type = serializers.CharField(required=False, allow_blank=True)
    vehicle_color = serializers.CharField(required=False, allow_blank=True)


class PlateLookupSerializer(serializers.Serializer):
    class Meta:
        pass  # Output only
