"""
accounts/citizen_views.py — Citizen app specific views
"""
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
