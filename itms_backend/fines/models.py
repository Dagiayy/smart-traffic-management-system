import uuid
import string
import random
from django.db import models
from django.utils import timezone
from accounts.models import CustomUser
from violations.models import Violation, ViolationType


class FineRule(models.Model):
    SEVERITY_CHOICES = [('MINOR', 'Minor'), ('MAJOR', 'Major'), ('CRITICAL', 'Critical')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation_type = models.ForeignKey(ViolationType, on_delete=models.CASCADE, related_name='fine_rules')
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=5, default='ETB')
    points_deducted = models.SmallIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    effective_from = models.DateField(default=timezone.now)

    class Meta:
        db_table = 'fines_fine_rule'
        unique_together = ['violation_type', 'severity', 'effective_from']
        ordering = ['-effective_from']

    def __str__(self):
        return f'{self.violation_type.code} {self.severity}: ETB {self.amount}'


class Fine(models.Model):
    STATUS_CHOICES = [
        ('UNPAID', 'Unpaid'), ('PAID', 'Paid'),
        ('PARTIALLY_PAID', 'Partially Paid'), ('WAIVED', 'Waived'), ('DISPUTED', 'Disputed'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    violation = models.OneToOneField(Violation, on_delete=models.CASCADE, related_name='fine')
    citizen = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='fines')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='UNPAID', db_index=True)
    due_date = models.DateField()
    waive_reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'fines_fine'
        ordering = ['-created_at']

    def __str__(self):
        return f'Fine {self.id} - {self.citizen.full_name}: ETB {self.amount} ({self.status})'

    @property
    def is_overdue(self):
        return self.status == 'UNPAID' and timezone.now().date() > self.due_date


class Payment(models.Model):
    METHOD_CHOICES = [
        ('TELEBIRR', 'TeleBirr'), ('CBE_BIRR', 'CBE Birr'),
        ('BANK_TRANSFER', 'Bank Transfer'), ('CASH', 'Cash'),
        ('MOBILE_MONEY', 'Mobile Money'), ('CARD', 'Card'),
    ]
    STATUS_CHOICES = [
        ('PENDING', 'Pending'), ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'), ('REFUNDED', 'Refunded'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    fine = models.ForeignKey(Fine, on_delete=models.CASCADE, related_name='payments')
    citizen = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=METHOD_CHOICES)
    transaction_reference = models.CharField(max_length=255, unique=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'fines_payment'
        ordering = ['-created_at']


def _receipt_number():
    chars = string.ascii_uppercase + string.digits
    return 'RCP-' + ''.join(random.choices(chars, k=8))


class Receipt(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.OneToOneField(Payment, on_delete=models.CASCADE, related_name='receipt')
    receipt_number = models.CharField(max_length=50, unique=True, default=_receipt_number)
    issued_at = models.DateTimeField(auto_now_add=True)
    pdf_url = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'fines_receipt'
        ordering = ['-issued_at']

    def __str__(self):
        return f'Receipt {self.receipt_number}'
