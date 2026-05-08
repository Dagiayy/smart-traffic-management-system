"""notifications/models.py"""
import uuid
from django.db import models
from accounts.models import CustomUser


class Notification(models.Model):
    TYPE_CHOICES = [
        ('VIOLATION_DETECTED', 'Violation Detected'),
        ('FINE_DUE', 'Fine Due'),
        ('PAYMENT_CONFIRMED', 'Payment Confirmed'),
        ('DISPUTE_UPDATE', 'Dispute Update'),
        ('TRAFFIC_ALERT', 'Traffic Alert'),
        ('CONGESTION_ALERT', 'Congestion Alert'),
        ('SYNC_REQUIRED', 'Sync Required'),
        ('SUPERVISOR_REVIEW', 'Supervisor Review'),
        ('POLICY_UPDATE', 'Policy Update'),
        ('GENERAL', 'General'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=30, choices=TYPE_CHOICES, default='GENERAL')
    is_read = models.BooleanField(default=False, db_index=True)
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications_notification'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user.full_name}: {self.title}'


class NotificationTemplate(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification_type = models.CharField(max_length=30, unique=True)
    title_template = models.CharField(max_length=255)
    message_template = models.TextField()
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'notifications_template'
