import uuid
from django.db import models
from accounts.models import CustomUser
from vehicles.models import Vehicle
from intersections.models import Intersection, TrafficCamera


class ViolationType(models.Model):
    SEVERITY_CHOICES = [
        ('MINOR', 'Minor'), ('MAJOR', 'Major'), ('CRITICAL', 'Critical'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=50, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    default_severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='MINOR')
    points_deducted = models.SmallIntegerField(default=0)
    legal_reference = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'violations_violation_type'
        ordering = ['name']

    def __str__(self):
        return f'{self.code}: {self.name}'


class Violation(models.Model):
    SOURCE_CHOICES = [
        ('AI_DETECTION', 'AI Detection'), ('OFFICER_FIELD', 'Officer Field'),
    ]
    STATUS_CHOICES = [
        ('DETECTED', 'Detected'), ('UNDER_REVIEW', 'Under Review'),
        ('CONFIRMED', 'Confirmed'), ('DISMISSED', 'Dismissed'),
        # Officer workflow statuses
        ('DRAFT', 'Draft'), ('SUBMITTED', 'Submitted'), ('PENDING_SYNC', 'Pending Sync'),
        ('SYNCED', 'Synced'), ('ACKNOWLEDGED', 'Acknowledged'),
        ('ESCALATED', 'Escalated'), ('CLOSED', 'Closed'),
    ]
    SEVERITY_CHOICES = ViolationType.SEVERITY_CHOICES

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation_type = models.ForeignKey(ViolationType, on_delete=models.PROTECT, related_name='violations')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='violations')
    intersection = models.ForeignKey(Intersection, on_delete=models.SET_NULL, null=True, blank=True, related_name='violations')
    camera = models.ForeignKey(TrafficCamera, on_delete=models.SET_NULL, null=True, blank=True)
    officer = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='issued_violations')
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DETECTED', db_index=True)
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='MINOR')
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    detected_speed = models.SmallIntegerField(null=True, blank=True)
    ai_confidence = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    notes = models.TextField(blank=True)
    # Officer field
    driver_name = models.CharField(max_length=255, blank=True)
    driver_license = models.CharField(max_length=50, blank=True)
    vehicle_color = models.CharField(max_length=50, blank=True)
    vehicle_type_field = models.CharField(max_length=50, blank=True)
    detected_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'violations_violation'
        ordering = ['-detected_at']
        indexes = [
            models.Index(fields=['status', '-detected_at']),
            models.Index(fields=['vehicle', '-detected_at']),
            models.Index(fields=['officer', '-detected_at']),
        ]

    def __str__(self):
        return f'{self.violation_type.code} - {self.vehicle.plate_number}'

    @property
    def plate_number(self):
        return self.vehicle.plate_number

    @property
    def location_name(self):
        return self.intersection.name if self.intersection else None


class ViolationEvidence(models.Model):
    FILE_TYPE_CHOICES = [('IMAGE', 'Image'), ('VIDEO', 'Video')]
    SOURCE_CHOICES = [('CAMERA', 'Camera'), ('OFFICER_UPLOAD', 'Officer Upload')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation = models.ForeignKey(Violation, on_delete=models.CASCADE, related_name='evidence_files')
    file = models.FileField(upload_to='evidence/%Y/%m/')
    file_url = models.URLField(max_length=500, blank=True)
    file_type = models.CharField(max_length=10, choices=FILE_TYPE_CHOICES, default='IMAGE')
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='OFFICER_UPLOAD')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'violations_violation_evidence'

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.file and not self.file_url:
            self.file_url = self.file.url
            super().save(update_fields=['file_url'])


class ViolationStatusHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation = models.ForeignKey(Violation, on_delete=models.CASCADE, related_name='status_history')
    old_status = models.CharField(max_length=30)
    new_status = models.CharField(max_length=30)
    changed_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True)
    reason = models.TextField(blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'violations_status_history'
        ordering = ['-changed_at']
