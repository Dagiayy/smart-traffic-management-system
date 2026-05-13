"""
accounts/citizen_views.py — Citizen app specific views
"""
from uuid import uuid4

import requests as http_requests

from django.conf import settings
from django.utils import timezone
from django.db.models import Sum
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import generics

from itms_backend.permissions import IsCitizen
from vehicles.models import Vehicle
from vehicles.serializers import VehicleSerializer
from violations.models import Violation
from violations.serializers import ViolationSerializer, ViolationSummarySerializer
from fines.models import Fine, Receipt
from fines.serializers import FineSerializer, ReceiptSerializer
from disputes.models import Dispute
from disputes.serializers import DisputeSerializer, CreateDisputeSerializer
from notifications.models import Notification
from notifications.serializers import NotificationSerializer
from ai_brain.models import CongestedZone
from intersections.models import Intersection
from .models import UserProfile
from .serializers import UserSerializer, UpdateUserSerializer


class CitizenViolationsView(generics.ListAPIView):
    permission_classes = [IsCitizen]
    serializer_class = ViolationSerializer

    def get_queryset(self):
        user = self.request.user
        vehicles = Vehicle.objects.filter(owner=user)
        qs = Violation.objects.filter(vehicle__in=vehicles).select_related(
            'violation_type', 'vehicle', 'intersection', 'officer'
        ).prefetch_related('evidence_files')

        status_filter = self.request.query_params.get('status')
        severity_filter = self.request.query_params.get('severity')
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        type_filter = self.request.query_params.get('type')

        if status_filter:
            qs = qs.filter(status=status_filter)
        if severity_filter:
            qs = qs.filter(severity=severity_filter)
        if date_from:
            qs = qs.filter(detected_at__date__gte=date_from)
        if date_to:
            qs = qs.filter(detected_at__date__lte=date_to)
        if type_filter:
            qs = qs.filter(violation_type__code=type_filter)
        return qs.order_by('-detected_at')


class CitizenViolationDetailView(generics.RetrieveAPIView):
    permission_classes = [IsCitizen]
    serializer_class = ViolationSerializer

    def get_queryset(self):
        return Violation.objects.filter(vehicle__owner=self.request.user)


class CitizenViolationSummaryView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        vehicles = Vehicle.objects.filter(owner=request.user)
        violations = Violation.objects.filter(vehicle__in=vehicles)
        unpaid_fines = Fine.objects.filter(
            citizen=request.user, status__in=['UNPAID', 'PARTIALLY_PAID']
        )
        profile = getattr(request.user, 'profile', None)
        return Response({
            'total_unpaid': unpaid_fines.aggregate(total=Sum('amount'))['total'] or 0,
            'unpaid_count': unpaid_fines.count(),
            'active_violations': violations.filter(status__in=['DETECTED', 'CONFIRMED', 'UNDER_REVIEW']).count(),
            'compliance_score': profile.compliance_score if profile else 100,
            'driver_status': profile.driver_status if profile else 'SAFE',
        })


class CitizenFinesView(generics.ListAPIView):
    permission_classes = [IsCitizen]
    serializer_class = FineSerializer

    def get_queryset(self):
        qs = Fine.objects.filter(citizen=self.request.user).select_related('violation')
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs.order_by('-created_at')


class CitizenFineDetailView(generics.RetrieveAPIView):
    permission_classes = [IsCitizen]
    serializer_class = FineSerializer

    def get_queryset(self):
        return Fine.objects.filter(citizen=self.request.user)


class PayFineView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request, pk):
        from fines.models import Payment
        from fines.serializers import PaymentSerializer, ReceiptSerializer
        try:
            fine = Fine.objects.get(pk=pk, citizen=request.user)
        except Fine.DoesNotExist:
            return Response({'error': 'Fine not found.'}, status=status.HTTP_404_NOT_FOUND)

        if fine.status == 'PAID':
            return Response({'error': 'Fine is already paid.'}, status=status.HTTP_400_BAD_REQUEST)

        payment_method = request.data.get('payment_method', 'TELEBIRR')
        transaction_ref = request.data.get('transaction_ref', '')

        # Create payment record
        payment = Payment.objects.create(
            fine=fine,
            citizen=request.user,
            amount=fine.amount - fine.amount_paid,
            payment_method=payment_method,
            transaction_reference=transaction_ref,
            status='COMPLETED',
            paid_at=timezone.now(),
        )

        # Update fine
        fine.amount_paid = fine.amount
        fine.status = 'PAID'
        fine.save()

        # Create receipt
        receipt = Receipt.objects.create(payment=payment)

        # Update compliance score
        try:
            profile = request.user.profile
            profile.recalculate_compliance_score()
        except Exception:
            pass

        # Notify citizen
        Notification.objects.create(
            user=request.user,
            title='Payment Confirmed',
            message=f'Your payment of ETB {fine.amount} has been confirmed.',
            notification_type='PAYMENT_CONFIRMED',
        )

        return Response({
            'receipt_id': str(receipt.id),
            'receipt_number': receipt.receipt_number,
            'status': 'PAID',
            'amount': str(fine.amount),
        })


class CitizenReceiptsView(generics.ListAPIView):
    permission_classes = [IsCitizen]
    serializer_class = ReceiptSerializer

    def get_queryset(self):
        return Receipt.objects.filter(
            payment__citizen=self.request.user
        ).select_related('payment', 'payment__fine').order_by('-issued_at')


class CitizenReceiptDetailView(generics.RetrieveAPIView):
    permission_classes = [IsCitizen]
    serializer_class = ReceiptSerializer

    def get_queryset(self):
        return Receipt.objects.filter(payment__citizen=self.request.user)


class CitizenDisputesView(generics.ListCreateAPIView):
    permission_classes = [IsCitizen]

    def get_serializer_class(self):
        return CreateDisputeSerializer if self.request.method == 'POST' else DisputeSerializer

    def get_queryset(self):
        return Dispute.objects.filter(citizen=self.request.user).order_by('-submitted_at')

    def perform_create(self, serializer):
        serializer.save(citizen=self.request.user)


class CitizenDisputeDetailView(generics.RetrieveDestroyAPIView):
    permission_classes = [IsCitizen]
    serializer_class = DisputeSerializer

    def get_queryset(self):
        return Dispute.objects.filter(citizen=self.request.user)

    def destroy(self, request, *args, **kwargs):
        dispute = self.get_object()
        if dispute.status != 'SUBMITTED':
            return Response({'error': 'Only pending disputes can be withdrawn.'},
                            status=status.HTTP_400_BAD_REQUEST)
        dispute.status = 'WITHDRAWN'
        dispute.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class CitizenVehiclesView(generics.ListCreateAPIView):
    permission_classes = [IsCitizen]
    serializer_class = VehicleSerializer

    def get_queryset(self):
        return Vehicle.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class CitizenVehicleDetailView(generics.DestroyAPIView):
    permission_classes = [IsCitizen]
    serializer_class = VehicleSerializer

    def get_queryset(self):
        return Vehicle.objects.filter(owner=self.request.user)


class CitizenTrafficAlertsView(generics.ListAPIView):
    permission_classes = [IsCitizen]

    def list(self, request, *args, **kwargs):
        from ai_brain.serializers import CongestedZoneSerializer
        qs = CongestedZone.objects.filter(
            resolved_at__isnull=True
        ).select_related('intersection').order_by('-detected_at')

        if not qs.exists():
            dummy_alerts = [
                {
                    "id": "dummy-001",
                    "title": "Heavy Congestion - Meskel Square",
                    "message": "Significant traffic buildup near Meskel Square. Expect 15-20 min delays.",
                    "type": "CONGESTION",
                    "severity": "HIGH",
                    "lat": 9.0054,
                    "lng": 38.7636,
                    "location_name": "Meskel Square",
                    "created_at": "2025-01-01T08:00:00Z",
                    "is_active": True,
                },
                {
                    "id": "dummy-002",
                    "title": "Road Maintenance - Bole Road",
                    "message": "Lane closures on Bole Road due to road maintenance work. Use alternate routes.",
                    "type": "MAINTENANCE",
                    "severity": "MEDIUM",
                    "lat": 9.0105,
                    "lng": 38.7892,
                    "location_name": "Bole Road",
                    "created_at": "2025-01-01T07:30:00Z",
                    "is_active": True,
                },
                {
                    "id": "dummy-003",
                    "title": "Accident Reported - Stadium Area",
                    "message": "Minor accident near National Stadium. Slow traffic in the vicinity.",
                    "type": "ACCIDENT",
                    "severity": "HIGH",
                    "lat": 9.0192,
                    "lng": 38.7526,
                    "location_name": "National Stadium",
                    "created_at": "2025-01-01T09:15:00Z",
                    "is_active": True,
                },
                {
                    "id": "dummy-004",
                    "title": "School Zone Advisory - Mexico Square",
                    "message": "Increased pedestrian activity near school zone. Drive carefully.",
                    "type": "ADVISORY",
                    "severity": "LOW",
                    "lat": 9.0168,
                    "lng": 38.7628,
                    "location_name": "Mexico Square",
                    "created_at": "2025-01-01T07:00:00Z",
                    "is_active": True,
                },
            ]
            return Response(dummy_alerts)

        from itms_backend.pagination import StandardPagination
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        serializer = CongestedZoneSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class CitizenNotificationsView(generics.ListAPIView):
    permission_classes = [IsCitizen]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


class MarkNotificationReadView(APIView):
    permission_classes = [IsCitizen]

    def patch(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, user=request.user)
            notif.is_read = True
            notif.save(update_fields=['is_read'])
            return Response({'message': 'Marked as read.'})
        except Notification.DoesNotExist:
            return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)


# ── Chapa Payment Views ────────────────────────────────────────────────────

class ChapaInitiateView(APIView):
    """POST /citizen/fines/<uuid:pk>/chapa/initiate/ — Initiate Chapa payment."""
    permission_classes = [IsCitizen]

    def post(self, request, pk):
        try:
            fine = Fine.objects.get(pk=pk, citizen=request.user)
        except Fine.DoesNotExist:
            return Response({'error': 'Fine not found.'}, status=status.HTTP_404_NOT_FOUND)

        if fine.status == 'PAID':
            return Response({'error': 'Fine is already paid.'}, status=status.HTTP_400_BAD_REQUEST)

        tx_ref = f'ITMS-{uuid4().hex[:12].upper()}'
        amount_due = fine.amount - fine.amount_paid
        user = request.user
        name_parts = (user.full_name or '').split(' ', 1)
        first_name = name_parts[0] if name_parts else 'Customer'
        last_name = name_parts[1] if len(name_parts) > 1 else 'User'

        chapa_secret_key = getattr(settings, 'CHAPA_SECRET_KEY', 'CHASECK_TEST-yourkey')

        payload = {
            'amount': str(amount_due),
            'currency': 'ETB',
            'email': user.email or '',
            'first_name': first_name,
            'last_name': last_name,
            'phone_number': user.phone_number or '',
            'tx_ref': tx_ref,
            'callback_url': 'http://127.0.0.1:8000/api/v1/citizen/chapa/callback/',
            'return_url': 'itms://payment/success',
            'customization': {'title': 'Traffic Fine Payment'},
        }

        try:
            resp = http_requests.post(
                'https://api.chapa.co/v1/transaction/initialize',
                json=payload,
                headers={
                    'Authorization': f'Bearer {chapa_secret_key}',
                    'Content-Type': 'application/json',
                },
                timeout=15,
            )
            resp_data = resp.json()
            if resp.status_code == 200 and resp_data.get('status') == 'success':
                checkout_url = resp_data.get('data', {}).get('checkout_url')
                return Response({'checkout_url': checkout_url, 'tx_ref': tx_ref})
        except Exception:
            pass

        # Chapa unavailable or failed — simulation mode
        return Response({'checkout_url': None, 'tx_ref': tx_ref, 'simulation': True})


class ChapaVerifyView(APIView):
    """GET /citizen/fines/<uuid:pk>/chapa/verify/?tx_ref=... — Verify Chapa payment."""
    permission_classes = [IsCitizen]

    def get(self, request, pk):
        from fines.models import Payment

        tx_ref = request.query_params.get('tx_ref', '').strip()
        if not tx_ref:
            return Response({'error': 'tx_ref is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            fine = Fine.objects.get(pk=pk, citizen=request.user)
        except Fine.DoesNotExist:
            return Response({'error': 'Fine not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Already paid — return existing receipt info
        if fine.status == 'PAID':
            receipt = Receipt.objects.filter(payment__fine=fine).order_by('-issued_at').first()
            if receipt:
                return Response({
                    'status': 'PAID',
                    'receipt_id': str(receipt.id),
                    'receipt_number': receipt.receipt_number,
                    'amount': str(fine.amount),
                })
            return Response({'status': 'PAID', 'amount': str(fine.amount)})

        chapa_secret_key = getattr(settings, 'CHAPA_SECRET_KEY', 'CHASECK_TEST-yourkey')

        try:
            resp = http_requests.get(
                f'https://api.chapa.co/v1/transaction/verify/{tx_ref}',
                headers={'Authorization': f'Bearer {chapa_secret_key}'},
                timeout=15,
            )
            resp_data = resp.json()
            chapa_status = resp_data.get('data', {}).get('status', '') if resp.status_code == 200 else ''

            if chapa_status == 'success':
                # Create payment record
                payment = Payment.objects.create(
                    fine=fine,
                    citizen=request.user,
                    amount=fine.amount - fine.amount_paid,
                    payment_method='CHAPA',
                    transaction_reference=tx_ref,
                    status='COMPLETED',
                    paid_at=timezone.now(),
                )

                # Update fine
                fine.amount_paid = fine.amount
                fine.status = 'PAID'
                fine.save()

                # Create receipt
                receipt = Receipt.objects.create(payment=payment)

                # Recalculate compliance score
                try:
                    request.user.profile.recalculate_compliance_score()
                except Exception:
                    pass

                # Notify citizen
                Notification.objects.create(
                    user=request.user,
                    title='Payment Confirmed',
                    message=f'Your Chapa payment of ETB {fine.amount} has been confirmed.',
                    notification_type='PAYMENT_CONFIRMED',
                )

                return Response({
                    'status': 'PAID',
                    'receipt_id': str(receipt.id),
                    'receipt_number': receipt.receipt_number,
                    'amount': str(fine.amount),
                })
        except Exception:
            pass

        return Response({'status': 'PENDING'})


class ChapaCallbackView(APIView):
    """POST /citizen/chapa/callback/ — Chapa webhook callback."""
    permission_classes = []  # Public endpoint for Chapa to call

    def post(self, request):
        # Acknowledge receipt; real verification is done via ChapaVerifyView
        return Response({'status': 'received'})


# ── Citizen Profile View ───────────────────────────────────────────────────

class CitizenProfileView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        user = request.user
        profile = getattr(user, 'profile', None)
        vehicles = Vehicle.objects.filter(owner=user)
        return Response({
            'id': str(user.id),
            'full_name': user.full_name,
            'email': user.email,
            'phone_number': user.phone_number,
            'national_id': user.national_id,
            'compliance_score': profile.compliance_score if profile else 100,
            'driver_status': profile.driver_status if profile else 'SAFE',
            'profile_photo_url': profile.profile_photo_url if profile else None,
            'address': profile.address if profile else None,
            'vehicles': VehicleSerializer(vehicles, many=True).data,
        })

    def patch(self, request):
        user = request.user
        allowed_fields = ['full_name', 'email', 'phone_number']
        for field in allowed_fields:
            if field in request.data:
                setattr(user, field, request.data[field])
        user.save()

        # Update profile fields
        profile, _ = UserProfile.objects.get_or_create(user=user)
        if 'address' in request.data:
            profile.address = request.data['address']
            profile.save(update_fields=['address'])

        return Response({'message': 'Profile updated.'})
