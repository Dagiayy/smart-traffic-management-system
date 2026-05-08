from rest_framework import serializers
from .models import Vehicle, DriverLicense


class VehicleSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source='owner.full_name', read_only=True)

    class Meta:
        model = Vehicle
        fields = ['id', 'plate_number', 'vehicle_type', 'make', 'model',
                  'year', 'color', 'registration_expiry', 'is_active',
                  'created_at', 'owner_name']
        read_only_fields = ['id', 'created_at', 'owner_name']

    def validate_plate_number(self, v):
        return v.upper().strip()


class DriverLicenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLicense
        fields = ['id', 'license_number', 'category', 'issued_date',
                  'expiry_date', 'status', 'points_balance']
        read_only_fields = ['id']
