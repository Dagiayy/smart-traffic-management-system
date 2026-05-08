import uuid
from django.db import models
from accounts.models import CustomUser


class Intersection(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    city = models.CharField(max_length=100, default='Addis Ababa')
    zone = models.CharField(max_length=100, blank=True)
    num_lanes = models.SmallIntegerField(default=4)
    is_active = models.BooleanField(default=True)
    sumo_node_id = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'intersections_intersection'
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def lat(self):
        return float(self.latitude)

    @property
    def lng(self):
        return float(self.longitude)


class Lane(models.Model):
    DIRECTION_CHOICES = [
        ('NORTH', 'North'), ('SOUTH', 'South'), ('EAST', 'East'), ('WEST', 'West'),
    ]
    LANE_TYPE_CHOICES = [
        ('THROUGH', 'Through'), ('TURN_LEFT', 'Turn Left'),
        ('TURN_RIGHT', 'Turn Right'), ('PEDESTRIAN', 'Pedestrian'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    intersection = models.ForeignKey(Intersection, on_delete=models.CASCADE, related_name='lanes')
    direction = models.CharField(max_length=10, choices=DIRECTION_CHOICES)
    lane_number = models.SmallIntegerField(default=1)
    lane_type = models.CharField(max_length=20, choices=LANE_TYPE_CHOICES, default='THROUGH')
    sumo_lane_id = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        db_table = 'intersections_lane'

    def __str__(self):
        return f'{self.intersection.name} - {self.direction} Lane {self.lane_number}'


class TrafficCamera(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    intersection = models.ForeignKey(Intersection, on_delete=models.CASCADE, related_name='cameras')
    lane = models.ForeignKey(Lane, on_delete=models.SET_NULL, null=True, blank=True)
    camera_code = models.CharField(max_length=50, unique=True)
    direction = models.CharField(max_length=10, choices=Lane.DIRECTION_CHOICES)
    stream_url = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    last_heartbeat = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'intersections_traffic_camera'

    def __str__(self):
        return f'Camera {self.camera_code} @ {self.intersection.name}'


class SignalState(models.Model):
    SOURCE_CHOICES = [
        ('AI', 'AI Decision'), ('ADMIN_OVERRIDE', 'Admin Override'), ('FIXED_TIMER', 'Fixed Timer'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    intersection = models.ForeignKey(Intersection, on_delete=models.CASCADE, related_name='signal_states')
    phase = models.CharField(max_length=50, default='NS_GREEN')
    green_duration = models.SmallIntegerField(default=30)
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='FIXED_TIMER')
    ai_confidence = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    activated_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    # For admin overrides
    override_reason = models.TextField(blank=True, null=True)
    overridden_by = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='signal_overrides'
    )

    class Meta:
        db_table = 'intersections_signal_state'
        ordering = ['-activated_at']
        get_latest_by = 'activated_at'

    def __str__(self):
        return f'{self.intersection.name} - {self.phase}'
