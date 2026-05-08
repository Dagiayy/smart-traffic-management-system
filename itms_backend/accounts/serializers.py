"""
accounts/serializers.py
"""
from django.utils import timezone
from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CustomUser, UserProfile, OTPVerification, PushToken


# ── User serializers ──────────────────────────────────────────────────────
class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['compliance_score', 'driver_status', 'assigned_zone',
                  'profile_photo_url', 'date_of_birth', 'address']


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'phone_number', 'full_name',
                  'role', 'badge_number', 'national_id', 'is_active',
                  'created_at', 'last_login', 'profile']
        read_only_fields = ['id', 'created_at', 'last_login', 'role']


class UserMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name', 'role', 'badge_number', 'phone_number', 'email']


# ── Registration ──────────────────────────────────────────────────────────
class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255)
    phone_number = serializers.CharField(max_length=20, required=False)
    email = serializers.EmailField(required=False)
    national_id = serializers.CharField(max_length=50, required=False)
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)
    # Optional initial vehicle
    plate_number = serializers.CharField(max_length=20, required=False, write_only=True)
    vehicle_type = serializers.CharField(required=False, write_only=True)

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match.'})
        if not data.get('phone_number') and not data.get('email'):
            raise serializers.ValidationError({'phone_number': 'Either phone or email is required.'})
        return data

    def validate_phone_number(self, v):
        if v and CustomUser.objects.filter(phone_number=v).exists():
            raise serializers.ValidationError('Phone number already registered.')
        return v

    def validate_email(self, v):
        if v and CustomUser.objects.filter(email=v).exists():
            raise serializers.ValidationError('Email already registered.')
        return v

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        plate_number = validated_data.pop('plate_number', None)
        vehicle_type = validated_data.pop('vehicle_type', None)
        password = validated_data.pop('password')

        phone = validated_data.get('phone_number', '')
        email = validated_data.get('email', '')
        username = phone or email.split('@')[0]
        # Ensure unique username
        base = username
        counter = 1
        while CustomUser.objects.filter(username=username).exists():
            username = f'{base}{counter}'
            counter += 1

        user = CustomUser.objects.create_user(
            username=username,
            password=password,
            role='CITIZEN',
            **{k: v for k, v in validated_data.items() if hasattr(CustomUser, k) or k in ['full_name', 'email', 'phone_number', 'national_id']}
        )
        UserProfile.objects.create(user=user)

        # Create initial vehicle if provided
        if plate_number:
            from vehicles.models import Vehicle
            Vehicle.objects.get_or_create(
                plate_number=plate_number.upper(),
                defaults={
                    'owner': user,
                    'vehicle_type': vehicle_type or 'CAR',
                }
            )
        return user


# ── Login ─────────────────────────────────────────────────────────────────
class LoginSerializer(serializers.Serializer):
    phone_or_email = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        identifier = data['phone_or_email'].strip()
        password = data['password']

        # Find user by phone or email
        user = None
        if '@' in identifier:
            try:
                user_obj = CustomUser.objects.get(email=identifier)
                user = authenticate(username=user_obj.username, password=password)
            except CustomUser.DoesNotExist:
                pass
        else:
            try:
                user_obj = CustomUser.objects.get(phone_number=identifier)
                user = authenticate(username=user_obj.username, password=password)
            except CustomUser.DoesNotExist:
                pass
            if not user:
                # Try username directly (for officer badge ID)
                user = authenticate(username=identifier, password=password)

        if not user:
            raise serializers.ValidationError({'detail': 'Invalid credentials.'})
        if not user.is_active:
            raise serializers.ValidationError({'detail': 'Account is deactivated.'})

        data['user'] = user
        return data

    def get_tokens(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': str(user.id),
                'full_name': user.full_name,
                'role': user.role,
                'email': user.email,
                'phone_number': user.phone_number,
                'badge_number': user.badge_number,
                'assigned_zone': getattr(getattr(user, 'profile', None), 'assigned_zone', None),
            }
        }


# ── OTP ───────────────────────────────────────────────────────────────────
class SendOTPSerializer(serializers.Serializer):
    phone_or_email = serializers.CharField()
    purpose = serializers.ChoiceField(choices=['verify', 'reset'])


class VerifyOTPSerializer(serializers.Serializer):
    phone_or_email = serializers.CharField()
    code = serializers.CharField(min_length=4, max_length=10)


class ResetPasswordSerializer(serializers.Serializer):
    phone_or_email = serializers.CharField()
    new_password = serializers.CharField(min_length=8, write_only=True)
    otp_token = serializers.CharField(write_only=True)

    def validate_new_password(self, v):
        from django.contrib.auth.password_validation import validate_password
        validate_password(v)
        return v


# ── Push token ─────────────────────────────────────────────────────────────
class PushTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushToken
        fields = ['token', 'platform']


# ── Admin user management ─────────────────────────────────────────────────
class CreateUserSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255)
    email = serializers.EmailField(required=False)
    phone_number = serializers.CharField(max_length=20, required=False)
    role = serializers.ChoiceField(choices=['OFFICER', 'SUPERVISOR', 'ADMIN', 'DEVELOPER'])
    badge_number = serializers.CharField(required=False, allow_blank=True)
    assigned_zone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(min_length=8, write_only=True, required=False)

    def create(self, validated_data):
        assigned_zone = validated_data.pop('assigned_zone', None)
        password = validated_data.pop('password', None) or CustomUser.objects.make_random_password()
        phone = validated_data.get('phone_number', '')
        email = validated_data.get('email', '')
        badge = validated_data.get('badge_number', '')
        username = badge or phone or email.split('@')[0]
        base = username
        counter = 1
        while CustomUser.objects.filter(username=username).exists():
            username = f'{base}{counter}'
            counter += 1
        user = CustomUser.objects.create_user(username=username, password=password, **validated_data)
        profile = UserProfile.objects.create(user=user, assigned_zone=assigned_zone)
        return user


class UpdateUserSerializer(serializers.ModelSerializer):
    assigned_zone = serializers.CharField(required=False, write_only=True)
    compliance_score = serializers.IntegerField(required=False, write_only=True)

    class Meta:
        model = CustomUser
        fields = ['full_name', 'email', 'phone_number', 'is_active',
                  'badge_number', 'assigned_zone', 'compliance_score']

    def update(self, instance, validated_data):
        assigned_zone = validated_data.pop('assigned_zone', None)
        compliance_score = validated_data.pop('compliance_score', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if assigned_zone or compliance_score:
            profile, _ = UserProfile.objects.get_or_create(user=instance)
            if assigned_zone:
                profile.assigned_zone = assigned_zone
            if compliance_score is not None:
                profile.compliance_score = compliance_score
            profile.save()
        return instance
