"""
accounts/views.py — Authentication views shared by all clients.
"""
from django.utils import timezone
from datetime import timedelta
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .models import CustomUser, UserProfile, OTPVerification, PushToken
from .serializers import (
    RegisterSerializer, LoginSerializer, SendOTPSerializer,
    VerifyOTPSerializer, ResetPasswordSerializer, UserSerializer,
    PushTokenSerializer, UpdateUserSerializer,
)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # Pre-process incoming data to support Flutter app's format
        data = request.data.copy()

        # Map Flutter field names to serializer field names
        if 'phone' in data and 'phone_number' not in data:
            data['phone_number'] = data['phone']

        # Auto-fill password_confirm if missing (Flutter sends only password)
        if 'password' in data and 'password_confirm' not in data:
            data['password_confirm'] = data['password']

        # Extract vehicles list before serialization (not a serializer field)
        vehicles_list = data.pop('vehicles', None)
        if isinstance(vehicles_list, list) and len(vehicles_list) > 0:
            # Use first vehicle as the flat plate_number/vehicle_type for serializer
            first = vehicles_list[0]
            if 'plate_number' not in data and 'plate_number' in first:
                data['plate_number'] = first.get('plate_number', '')
            if 'vehicle_type' not in data and 'type' in first:
                data['vehicle_type'] = first.get('type', 'CAR')
            # Keep remaining vehicles to create after user save
            extra_vehicles = vehicles_list[1:]
        else:
            extra_vehicles = []

        serializer = RegisterSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Create additional vehicles from the list
        if extra_vehicles:
            from vehicles.models import Vehicle
            for v in extra_vehicles:
                plate = v.get('plate_number', '').strip().upper()
                vtype = v.get('type', 'CAR')
                if plate:
                    Vehicle.objects.get_or_create(
                        plate_number=plate,
                        defaults={'owner': user, 'vehicle_type': vtype},
                    )

        # Send email verification OTP if user has email
        email_verification_required = False
        if user.email:
            try:
                code = OTPVerification.generate_otp()
                otp = OTPVerification(
                    user=user,
                    purpose='VERIFY_EMAIL',
                    expires_at=timezone.now() + timedelta(minutes=10),
                )
                otp.set_code(code)
                otp.save()
                _send_otp(user, code, 'VERIFY_EMAIL')
                email_verification_required = True
            except Exception:
                pass

        refresh = RefreshToken.for_user(user)
        response_data = {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': str(user.id),
                'full_name': user.full_name,
                'role': user.role,
                'email': user.email,
                'phone_number': user.phone_number,
            },
        }
        if email_verification_required:
            response_data['email_verification_required'] = True

        return Response(response_data, status=status.HTTP_201_CREATED)


class SendEmailVerificationView(APIView):
    """POST /auth/email/send-verification/ — resend email verification OTP."""
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)

        user = CustomUser.objects.filter(email=email).first()
        if not user:
            return Response({'message': 'If an account exists, a code has been sent.'})

        code = OTPVerification.generate_otp()
        otp = OTPVerification(
            user=user,
            purpose='VERIFY_EMAIL',
            expires_at=timezone.now() + timedelta(minutes=10),
        )
        otp.set_code(code)
        otp.save()
        _send_otp(user, code, 'VERIFY_EMAIL')
        return Response({'message': 'Verification code sent.'})


class VerifyEmailView(APIView):
    """POST /auth/email/verify/ — verify email with OTP code."""
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        code = request.data.get('code', '').strip()

        if not email or not code:
            return Response({'error': 'Email and code are required.'}, status=status.HTTP_400_BAD_REQUEST)

        user = CustomUser.objects.filter(email=email).first()
        if not user:
            return Response({'error': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)

        otp = OTPVerification.objects.filter(
            user=user,
            purpose='VERIFY_EMAIL',
            used_at__isnull=True,
        ).order_by('-created_at').first()

        if not otp or otp.is_expired() or not otp.verify_code(code):
            return Response({'error': 'Invalid or expired code.'}, status=status.HTTP_400_BAD_REQUEST)

        otp.mark_used()
        return Response({'message': 'Email verified successfully.'})


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        tokens = serializer.get_tokens(user)
        return Response(tokens)


class LogoutView(APIView):
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
        except TokenError:
            pass
        return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)


class MeView(APIView):
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def put(self, request):
        serializer = UpdateUserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data)


class SendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data['phone_or_email'].strip()
        purpose = serializer.validated_data['purpose']

        # Find user
        user = None
        if '@' in identifier:
            user = CustomUser.objects.filter(email=identifier).first()
        else:
            user = CustomUser.objects.filter(phone_number=identifier).first()

        if not user:
            # Don't reveal user existence
            return Response({'message': 'If an account exists, a code has been sent.'})

        # Rate limiting — max 3 OTPs per 10 minutes
        recent = OTPVerification.objects.filter(
            user=user,
            created_at__gte=timezone.now() - timedelta(minutes=10)
        ).count()
        if recent >= 3:
            return Response({'error': 'Too many OTP requests. Try again later.'},
                            status=status.HTTP_429_TOO_MANY_REQUESTS)

        code = OTPVerification.generate_otp()
        otp = OTPVerification(
            user=user,
            purpose='RESET_PASSWORD' if purpose == 'reset' else 'VERIFY_PHONE',
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        otp.set_code(code)
        otp.save()

        # Send OTP (console backend in dev)
        _send_otp(user, code, purpose)

        return Response({'message': 'Verification code sent.'})


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data['phone_or_email'].strip()
        code = serializer.validated_data['code']

        if '@' in identifier:
            user = CustomUser.objects.filter(email=identifier).first()
        else:
            user = CustomUser.objects.filter(phone_number=identifier).first()

        if not user:
            return Response({'error': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)

        otp = OTPVerification.objects.filter(
            user=user, used_at__isnull=True
        ).order_by('-created_at').first()

        if not otp or otp.is_expired() or not otp.verify_code(code):
            return Response({'error': 'Invalid or expired code.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_token = otp.mark_used()
        return Response({'message': 'OTP verified.', 'otp_token': otp_token})


class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data['phone_or_email'].strip()
        new_password = serializer.validated_data['new_password']
        otp_token = serializer.validated_data['otp_token']

        # Find valid OTP token
        otp = OTPVerification.objects.filter(otp_token=otp_token, used_at__isnull=False).first()
        if not otp:
            return Response({'error': 'Invalid or expired reset token.'}, status=status.HTTP_400_BAD_REQUEST)
        # Make sure OTP token is fresh (< 15 min)
        if timezone.now() > otp.used_at + timedelta(minutes=15):
            return Response({'error': 'Reset token expired.'}, status=status.HTTP_400_BAD_REQUEST)

        user = otp.user
        user.set_password(new_password)
        user.save()
        # Invalidate the OTP token
        otp.otp_token = None
        otp.save(update_fields=['otp_token'])

        return Response({'message': 'Password reset successfully.'})


class PushTokenView(APIView):
    def post(self, request):
        serializer = PushTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        PushToken.objects.update_or_create(
            user=request.user,
            token=serializer.validated_data['token'],
            defaults={
                'platform': serializer.validated_data['platform'],
                'is_active': True
            }
        )
        return Response({'message': 'Push token registered.'})


def _send_otp(user, code, purpose):
    """Send OTP via email or SMS. In dev, print to console."""
    print(f'\n[OTP] User: {user.full_name} | Purpose: {purpose} | Code: {code}\n')
    # TODO: Integrate with email/SMS provider for production
    if user.email:
        from django.core.mail import send_mail
        try:
            send_mail(
                subject='Your ITMS Verification Code',
                message=f'Your code is: {code}\nExpires in 10 minutes.',
                from_email=None,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception:
            pass
