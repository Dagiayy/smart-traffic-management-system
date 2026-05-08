"""
accounts/models.py
Central user management for ALL system roles.
"""
import uuid
import hashlib
import secrets
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('CITIZEN', 'Citizen'),
        ('OFFICER', 'Officer'),
        ('SUPERVISOR', 'Supervisor'),
        ('ADMIN', 'Admin'),
        ('DEVELOPER', 'Developer'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, null=True, blank=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    full_name = models.CharField(max_length=255, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='CITIZEN')
    national_id = models.CharField(max_length=50, unique=True, null=True, blank=True)
    badge_number = models.CharField(max_length=50, unique=True, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'full_name']

    class Meta:
        db_table = 'accounts_user'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.full_name or self.username} ({self.role})'

    @property
    def is_citizen(self): return self.role == 'CITIZEN'

    @property
    def is_officer(self): return self.role in ('OFFICER', 'SUPERVISOR', 'ADMIN')

    @property
    def is_supervisor(self): return self.role in ('SUPERVISOR', 'ADMIN')

    @property
    def is_admin_user(self): return self.role == 'ADMIN'

    @property
    def is_developer(self): return self.role in ('DEVELOPER', 'ADMIN')


class UserProfile(models.Model):
    DRIVER_STATUS_CHOICES = [
        ('SAFE', 'Safe'),
        ('WARNING', 'Warning'),
        ('HIGH_RISK', 'High Risk'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='profile')
    profile_photo_url = models.URLField(max_length=500, blank=True, null=True)
    date_of_birth = models.DateField(null=True, blank=True)
    address = models.TextField(blank=True, null=True)
    # Citizen-specific
    compliance_score = models.IntegerField(default=100)
    driver_status = models.CharField(max_length=20, choices=DRIVER_STATUS_CHOICES, default='SAFE')
    # Officer-specific
    assigned_zone = models.CharField(max_length=100, blank=True, null=True)
    supervisor = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='supervised_officers', limit_choices_to={'role': 'SUPERVISOR'}
    )

    class Meta:
        db_table = 'accounts_user_profile'

    def __str__(self):
        return f'Profile: {self.user.full_name}'

    def recalculate_compliance_score(self):
        """Recalculate compliance score based on violation history."""
        from violations.models import Violation
        recent_violations = Violation.objects.filter(
            vehicle__owner=self.user,
            detected_at__gte=timezone.now() - timezone.timedelta(days=365),
            status='CONFIRMED'
        ).count()
        # Deduct points per violation
        base_score = 100
        score = max(0, base_score - (recent_violations * 10))
        self.compliance_score = score
        # Update driver status
        if score >= 80:
            self.driver_status = 'SAFE'
        elif score >= 50:
            self.driver_status = 'WARNING'
        else:
            self.driver_status = 'HIGH_RISK'
        self.save(update_fields=['compliance_score', 'driver_status'])
        return score


class OTPVerification(models.Model):
    PURPOSE_CHOICES = [
        ('VERIFY_PHONE', 'Verify Phone'),
        ('VERIFY_EMAIL', 'Verify Email'),
        ('RESET_PASSWORD', 'Reset Password'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='otps')
    code_hash = models.CharField(max_length=64)  # Stored as SHA-256 hash
    purpose = models.CharField(max_length=30, choices=PURPOSE_CHOICES)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    # Verified token — returned after OTP is verified, used for password reset
    otp_token = models.CharField(max_length=64, blank=True, null=True, unique=True)

    class Meta:
        db_table = 'accounts_otp_verification'
        ordering = ['-created_at']

    def set_code(self, code):
        self.code_hash = hashlib.sha256(code.encode()).hexdigest()

    def verify_code(self, code):
        return self.code_hash == hashlib.sha256(code.encode()).hexdigest()

    def is_expired(self):
        return timezone.now() > self.expires_at

    def is_used(self):
        return self.used_at is not None

    def mark_used(self):
        self.used_at = timezone.now()
        # Generate one-time token for password reset flow
        self.otp_token = secrets.token_urlsafe(32)
        self.save(update_fields=['used_at', 'otp_token'])
        return self.otp_token

    @classmethod
    def generate_otp(cls):
        """Generate a 6-digit OTP code."""
        import random
        return str(random.randint(100000, 999999))


class PushToken(models.Model):
    PLATFORM_CHOICES = [('ANDROID', 'Android'), ('IOS', 'iOS')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='push_tokens')
    token = models.TextField()
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_push_token'
        unique_together = ['user', 'token']

    def __str__(self):
        return f'{self.user.full_name} - {self.platform}'


class UserSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='sessions')
    refresh_token_jti = models.CharField(max_length=255, unique=True)
    device_info = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_user_session'
        ordering = ['-last_used_at']

    def __str__(self):
        return f'Session: {self.user.full_name} at {self.last_used_at}'
