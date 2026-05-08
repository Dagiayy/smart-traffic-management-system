"""ai_brain/models.py — Bridge between AI service and Django backend"""
import uuid
from django.db import models
from accounts.models import CustomUser
from intersections.models import Intersection


class AISession(models.Model):
    STATUS_CHOICES = [
        ('RUNNING', 'Running'), ('COMPLETED', 'Completed'),
        ('STOPPED', 'Stopped'), ('FAILED', 'Failed'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    scenario_id = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='RUNNING')
    rl_params = models.JSONField(default=dict)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    started_by = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='ai_sessions'
    )

    class Meta:
        db_table = 'ai_brain_session'
        ordering = ['-started_at']

    def __str__(self):
        return f'AI Session: {self.name} ({self.status})'

    @property
    def latest_avg_reward(self):
        ep = self.episodes.order_by('-episode_number').first()
        return float(ep.total_reward) if ep else 0

    @property
    def total_episodes(self):
        return self.episodes.count()


class RLEpisode(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(AISession, on_delete=models.CASCADE, related_name='episodes')
    episode_number = models.IntegerField()
    total_reward = models.DecimalField(max_digits=10, decimal_places=4)
    avg_waiting_time = models.DecimalField(max_digits=8, decimal_places=2)
    throughput = models.IntegerField(default=0)
    pedestrian_delay = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    epsilon = models.DecimalField(max_digits=6, decimal_places=4, default=1.0)
    loss = models.DecimalField(max_digits=10, decimal_places=6, null=True, blank=True)
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_brain_rl_episode'
        ordering = ['episode_number']
        unique_together = ['session', 'episode_number']


class SignalDecision(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(AISession, on_delete=models.SET_NULL, null=True, blank=True, related_name='signal_decisions')
    intersection = models.ForeignKey(Intersection, on_delete=models.CASCADE, related_name='ai_decisions')
    episode = models.ForeignKey(RLEpisode, on_delete=models.SET_NULL, null=True, blank=True)
    phase = models.CharField(max_length=50)
    duration_seconds = models.SmallIntegerField()
    confidence = models.DecimalField(max_digits=5, decimal_places=4)
    decided_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_brain_signal_decision'
        ordering = ['-decided_at']


class CongestedZone(models.Model):
    SEVERITY_CHOICES = [
        ('LOW', 'Low'), ('MEDIUM', 'Medium'), ('HIGH', 'High'), ('CRITICAL', 'Critical'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    intersection = models.ForeignKey(Intersection, on_delete=models.CASCADE, related_name='congestion_events')
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES)
    affected_lanes = models.JSONField(default=list)
    estimated_delay_seconds = models.IntegerField(default=0)
    detected_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'ai_brain_congested_zone'
        ordering = ['-detected_at']

    def __str__(self):
        return f'Congestion @ {self.intersection.name} ({self.severity})'


class AIAlert(models.Model):
    ALERT_TYPE_CHOICES = [
        ('CONGESTION', 'Congestion'), ('CAMERA_FAILURE', 'Camera Failure'),
        ('AI_ANOMALY', 'AI Anomaly'), ('HIGH_VIOLATION_RATE', 'High Violation Rate'),
        ('SYSTEM', 'System'),
    ]
    SEVERITY_CHOICES = [
        ('INFO', 'Info'), ('WARNING', 'Warning'), ('ERROR', 'Error'), ('CRITICAL', 'Critical'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    alert_type = models.CharField(max_length=30, choices=ALERT_TYPE_CHOICES)
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='INFO')
    message = models.TextField()
    intersection = models.ForeignKey(Intersection, on_delete=models.SET_NULL, null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'ai_brain_alert'
        ordering = ['-created_at']


class ExperimentConfig(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    rl_params = models.JSONField(default=dict)
    sumo_scenario = models.CharField(max_length=100, blank=True)
    created_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_brain_experiment_config'
        ordering = ['-created_at']


class SimulationLog(models.Model):
    LEVEL_CHOICES = [('DEBUG', 'Debug'), ('INFO', 'Info'), ('WARNING', 'Warning'), ('ERROR', 'Error')]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(AISession, on_delete=models.CASCADE, null=True, blank=True, related_name='logs')
    level = models.CharField(max_length=10, choices=LEVEL_CHOICES, default='INFO')
    message = models.TextField()
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_brain_simulation_log'
        ordering = ['-created_at']
