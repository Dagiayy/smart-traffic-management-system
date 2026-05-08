import uuid
from django.db import models
from accounts.models import CustomUser


class Vehicle(models.Model):
    VEHICLE_TYPE_CHOICES = [
        ('CAR', 'Car'), ('MOTORCYCLE', 'Motorcycle'), ('TRUCK', 'Truck'),
        ('BUS', 'Bus'), ('OTHER', 'Other'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plate_number = models.CharField(max_length=20, unique=True, db_index=True)
    owner = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='vehicles')
    vehicle_type = models.CharField(max_length=20, choices=VEHICLE_TYPE_CHOICES, default='CAR')
    make = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    year = models.SmallIntegerField(null=True, blank=True)
    color = models.CharField(max_length=50, blank=True)
    registration_expiry = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'vehicles_vehicle'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.plate_number} ({self.vehicle_type})'


class DriverLicense(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'), ('SUSPENDED', 'Suspended'),
        ('REVOKED', 'Revoked'), ('EXPIRED', 'Expired'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='driver_license')
    license_number = models.CharField(max_length=50, unique=True)
    category = models.CharField(max_length=20, blank=True)
    issued_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    points_balance = models.IntegerField(default=12)

    class Meta:
        db_table = 'vehicles_driver_license'

    def __str__(self):
        return f'{self.license_number} ({self.user.full_name})'


class VehicleOwnerHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='owner_history')
    owner = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name='owned_vehicles_history')
    from_date = models.DateField()
    to_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'vehicles_owner_history'
