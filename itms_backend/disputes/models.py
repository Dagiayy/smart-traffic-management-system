"""disputes/models.py"""
import uuid
from django.db import models
from accounts.models import CustomUser
from violations.models import Violation


class Dispute(models.Model):
    REASON_CHOICES = [
        ('WRONG_PLATE', 'Wrong Plate'), ('NOT_MY_VEHICLE', 'Not My Vehicle'),
        ('TECHNICAL_ERROR', 'Technical Error'), ('EMERGENCY_CASE', 'Emergency Case'),
        ('WRONG_VEHICLE', 'Wrong Vehicle'), ('INCORRECT_DETECTION', 'Incorrect Detection'),
        ('FALSE_VIOLATION', 'False Violation'), ('OTHER', 'Other'),
    ]
    STATUS_CHOICES = [
        ('SUBMITTED', 'Submitted'), ('UNDER_REVIEW', 'Under Review'),
        ('APPROVED', 'Approved'), ('REJECTED', 'Rejected'), ('WITHDRAWN', 'Withdrawn'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation = models.ForeignKey(Violation, on_delete=models.CASCADE, related_name='disputes')
    citizen = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='disputes')
    reason = models.CharField(max_length=30, choices=REASON_CHOICES)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='SUBMITTED', db_index=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'disputes_dispute'
        ordering = ['-submitted_at']

    def __str__(self):
        return f'Dispute {self.id} ({self.status})'


class DisputeEvidence(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='evidence')
    file = models.FileField(upload_to='dispute_evidence/%Y/%m/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'disputes_dispute_evidence'


class DisputeDecision(models.Model):
    DECISION_CHOICES = [('APPROVED', 'Approved'), ('REJECTED', 'Rejected')]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.OneToOneField(Dispute, on_delete=models.CASCADE, related_name='decision')
    decided_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True)
    decision = models.CharField(max_length=10, choices=DECISION_CHOICES)
    reason = models.TextField()
    decided_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'disputes_dispute_decision'
