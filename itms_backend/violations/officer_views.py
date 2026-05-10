"""violations/officer_views.py — Officer & Supervisor field enforcement views"""
from datetime import timedelta
from django.utils import timezone
from django.db import transaction
from django.db.models import Count, Q, Sum
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from itms_backend.permissions import IsOfficerOrAbove, IsSupervisorOrAbove
from vehicles.models import Vehicle
from intersections.models import Intersection
from fines.models import FineRule, Fine
from .models import Violation, ViolationEvidence, ViolationType, ViolationStatusHistory
from .serializers import ViolationSerializer, ViolationTypeSerializer, CreateTicketSerializer


class OfficerTicketsView(APIView):
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        qs = Violation.objects.filter(
            officer=request.user, source='OFFICER_FIELD'
        ).select_related('violation_type', 'vehicle', 'intersection')

        status_f = request.query_params.get('status')
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        q = request.query_params.get('q', '').strip()
        severity_f = request.query_params.get('severity')
        if status_f:
            qs = qs.filter(status=status_f)
        if severity_f:
            qs = qs.filter(severity=severity_f)
        if date_from:
            qs = qs.filter(detected_at__date__gte=date_from)
        if date_to:
            qs = qs.filter(detected_at__date__lte=date_to)
        if q:
            qs = qs.filter(
                Q(vehicle__plate_number__icontains=q) |
                Q(driver_name__icontains=q) |
                Q(driver_license__icontains=q) |
                Q(violation_type__name__icontains=q) |
                Q(notes__icontains=q)
            )

        from itms_backend.pagination import StandardPagination
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs.order_by('-detected_at'), request)
        return paginator.get_paginated_response(ViolationSerializer(page, many=True, context={'request': request}).data)

    def post(self, request):
        plate = request.data.get('plate_number', '').upper().strip()
        violation_type_id = request.data.get('violation_type_id')
        severity = request.data.get('severity', 'MINOR')
        notes = request.data.get('notes', '')
        driver_name = request.data.get('driver_name', '')
        driver_license = request.data.get('driver_license', '')
        vehicle_color = request.data.get('vehicle_color', '')
        vehicle_type = request.data.get('vehicle_type', '')
        location_lat = request.data.get('location_lat')
        location_lng = request.data.get('location_lng')
        intersection_id = request.data.get('intersection_id')

        if not plate:
            return Response({'error': 'plate_number is required.'}, status=400)
        if not violation_type_id:
            return Response({'error': 'violation_type_id is required.'}, status=400)

        # Get or create vehicle
        vehicle, _ = Vehicle.objects.get_or_create(
            plate_number=plate,
            defaults={'vehicle_type': vehicle_type or 'CAR', 'color': vehicle_color}
        )

        # Get violation type
        try:
            vtype = ViolationType.objects.get(pk=violation_type_id)
        except ViolationType.DoesNotExist:
            return Response({'error': 'Invalid violation_type_id.'}, status=400)

        # Get intersection
        intersection = None
        if intersection_id:
            try:
                intersection = Intersection.objects.get(pk=intersection_id)
            except Intersection.DoesNotExist:
                pass

        with transaction.atomic():
            violation = Violation.objects.create(
                violation_type=vtype,
                vehicle=vehicle,
                officer=request.user,
                source='OFFICER_FIELD',
                status='DRAFT',
                severity=severity or vtype.default_severity,
                intersection=intersection,
                latitude=location_lat,
                longitude=location_lng,
                notes=notes,
                driver_name=driver_name,
                driver_license=driver_license,
                vehicle_color=vehicle_color,
                vehicle_type_field=vehicle_type,
                detected_at=timezone.now(),
            )

            # Handle evidence files
            evidence_files = request.FILES.getlist('evidence_files')
            for ev_file in evidence_files:
                ViolationEvidence.objects.create(
                    violation=violation,
                    file=ev_file,
                    file_type='IMAGE',
                    source='OFFICER_UPLOAD',
                )

            # Log status
            ViolationStatusHistory.objects.create(
                violation=violation, old_status='', new_status='DRAFT', changed_by=request.user
            )

        return Response(ViolationSerializer(violation, context={'request': request}).data,
                        status=status.HTTP_201_CREATED)


class OfficerTicketDetailView(APIView):
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    permission_classes = [IsOfficerOrAbove]

    def _get_violation(self, request, pk):
        try:
            return Violation.objects.get(pk=pk, officer=request.user, source='OFFICER_FIELD')
        except Violation.DoesNotExist:
            return None

    def get(self, request, pk):
        v = self._get_violation(request, pk)
        if not v:
            return Response({'error': 'Not found.'}, status=404)
        return Response(ViolationSerializer(v, context={'request': request}).data)

    def patch(self, request, pk):
        v = self._get_violation(request, pk)
        if not v:
            return Response({'error': 'Not found.'}, status=404)
        if v.status not in ('DRAFT', 'PENDING_SYNC'):
            return Response({'error': 'Cannot edit submitted ticket.'}, status=400)

        for field in ['notes', 'severity', 'driver_name', 'driver_license', 'vehicle_color']:
            if field in request.data:
                setattr(v, field, request.data[field])
        v.save()

        # Additional evidence
        for ev_file in request.FILES.getlist('evidence_files'):
            ViolationEvidence.objects.create(
                violation=v, file=ev_file, file_type='IMAGE', source='OFFICER_UPLOAD')

        return Response(ViolationSerializer(v, context={'request': request}).data)


class SubmitTicketView(APIView):
    permission_classes = [IsOfficerOrAbove]

    def post(self, request, pk):
        try:
            violation = Violation.objects.get(pk=pk, officer=request.user)
        except Violation.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)

        if violation.status not in ('DRAFT', 'PENDING_SYNC'):
            return Response({'error': 'Already submitted.'}, status=400)

        old_status = violation.status
        violation.status = 'SUBMITTED'
        violation.save()

        ViolationStatusHistory.objects.create(
            violation=violation, old_status=old_status, new_status='SUBMITTED', changed_by=request.user
        )

        # Auto-create fine
        _create_fine_for_violation(violation)

        # Notify via WebSocket
        _broadcast_new_violation(violation)

        # Notify officer via WebSocket sync channel
        _broadcast_officer_sync(request.user, violation, 'synced')

        return Response({'message': 'Ticket submitted.', 'status': 'SUBMITTED'})


class BulkSyncView(APIView):
    permission_classes = [IsOfficerOrAbove]

    def post(self, request):
        tickets = request.data.get('tickets', [])
        synced = []
        failed = []

        for ticket_data in tickets:
            try:
                local_id = ticket_data.get('local_id')
                plate = (ticket_data.get('plate_number') or '').upper().strip()
                vtype_id = ticket_data.get('violation_type_id')

                if not plate or not vtype_id:
                    failed.append(local_id)
                    continue

                vehicle, _ = Vehicle.objects.get_or_create(plate_number=plate, defaults={'vehicle_type': 'CAR'})
                vtype = ViolationType.objects.filter(pk=vtype_id).first()
                if not vtype:
                    failed.append(local_id)
                    continue

                violation = Violation.objects.create(
                    violation_type=vtype,
                    vehicle=vehicle,
                    officer=request.user,
                    source='OFFICER_FIELD',
                    status='SUBMITTED',
                    severity=ticket_data.get('severity', 'MINOR'),
                    notes=ticket_data.get('notes', ''),
                    driver_name=ticket_data.get('driver_name', ''),
                    driver_license=ticket_data.get('driver_license', ''),
                    detected_at=timezone.now(),
                )
                _create_fine_for_violation(violation)
                synced.append(local_id)
            except Exception:
                failed.append(ticket_data.get('local_id'))

        return Response({'synced': synced, 'failed': failed})


class PlateLookupView(APIView):
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        plate = request.query_params.get('plate', '').upper().strip()
        if not plate:
            return Response({'error': 'plate parameter required.'}, status=400)

        try:
            vehicle = Vehicle.objects.get(plate_number=plate)
            from vehicles.models import DriverLicense
            license_status = None
            if vehicle.owner:
                try:
                    lic = vehicle.owner.driver_license
                    license_status = lic.status
                except Exception:
                    pass
            outstanding_fines = Fine.objects.filter(
                citizen=vehicle.owner, status__in=['UNPAID', 'PARTIALLY_PAID']
            ).count() if vehicle.owner else 0

            return Response({
                'vehicle': {
                    'plate_number': vehicle.plate_number,
                    'type': vehicle.vehicle_type,
                    'make': vehicle.make,
                    'model': vehicle.model,
                    'color': vehicle.color,
                },
                'owner_name': vehicle.owner.full_name if vehicle.owner else None,
                'license_status': license_status,
                'violation_history_count': Violation.objects.filter(vehicle=vehicle).count(),
                'outstanding_fines': outstanding_fines,
            })
        except Vehicle.DoesNotExist:
            return Response({
                'vehicle': None, 'owner_name': None, 'license_status': None,
                'violation_history_count': 0, 'outstanding_fines': 0,
                'message': 'Vehicle not found in system.'
            })


class ViolationTypesView(generics.ListAPIView):
    permission_classes = [IsOfficerOrAbove]
    serializer_class = ViolationTypeSerializer
    queryset = ViolationType.objects.filter(is_active=True).order_by('name')


class OfficerDashboardView(APIView):
    """Aggregated dashboard stats for the authenticated officer."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        officer = request.user
        today = timezone.now().date()
        week_ago = today - timedelta(days=7)

        base = Violation.objects.filter(officer=officer, source='OFFICER_FIELD')

        tickets_today = base.filter(detected_at__date=today).count()
        tickets_week  = base.filter(detected_at__date__gte=week_ago).count()
        tickets_month = base.filter(detected_at__date__gte=today.replace(day=1)).count()
        pending = base.filter(status='DRAFT').count()
        submitted = base.filter(status='SUBMITTED').count()
        confirmed = base.filter(status='CONFIRMED').count()
        dismissed = base.filter(status='DISMISSED').count()
        total     = base.count()

        return Response({
            'tickets_today': tickets_today,
            'tickets_week': tickets_week,
            'tickets_month': tickets_month,
            'pending_submissions': pending,
            'submitted_count': submitted,
            'confirmed_count': confirmed,
            'dismissed_count': dismissed,
            'total_tickets': total,
            'unsynced_count': 0,
            'alerts': [],
        })


class OfficerAnalyticsView(APIView):
    """Officer-specific analytics for the reports page."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        officer = request.user
        period  = request.query_params.get('period', 'week')
        today   = timezone.now().date()

        if period == 'day':
            date_from = today
        elif period == 'month':
            date_from = today.replace(day=1)
        else:
            date_from = today - timedelta(days=7)

        base = Violation.objects.filter(
            officer=officer, source='OFFICER_FIELD',
            detected_at__date__gte=date_from
        )

        total     = base.count()
        confirmed = base.filter(status='CONFIRMED').count()
        dismissed = base.filter(status='DISMISSED').count()
        critical  = base.filter(severity='CRITICAL').count()
        major     = base.filter(severity='MAJOR').count()
        minor     = base.filter(severity='MINOR').count()

        # Violations by type
        by_type = list(
            base.values('violation_type__name')
                .annotate(count=Count('id'))
                .order_by('-count')[:10]
        )
        by_type_formatted = [{'name': r['violation_type__name'], 'count': r['count']} for r in by_type]

        # Daily breakdown — last 7 days counts
        daily = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            daily.append(base.filter(detected_at__date=d).count())

        # Total fines amount from this officer's confirmed violations
        total_fines = Fine.objects.filter(
            violation__officer=officer,
            violation__detected_at__date__gte=date_from,
        ).aggregate(total=Sum('amount'))['total'] or 0

        return Response({
            'period': period,
            'total': total,
            'confirmed': confirmed,
            'dismissed': dismissed,
            'critical': critical,
            'major': major,
            'minor': minor,
            'by_type': by_type_formatted,
            'daily': daily,
            'total_collected': float(total_fines),
        })


class OfficerDailyReportView(APIView):
    """Officer's own daily performance report."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        officer = request.user
        today   = timezone.now().date()

        base = Violation.objects.filter(
            officer=officer, source='OFFICER_FIELD', detected_at__date=today
        )
        tickets_issued  = base.count()
        fines_generated = Fine.objects.filter(
            violation__officer=officer, created_at__date=today
        ).count()
        escalated = base.filter(status='ESCALATED').count()

        return Response({
            'tickets_issued': tickets_issued,
            'fines_generated': fines_generated,
            'escalated': escalated,
            'sync_failures': 0,
            'total': tickets_issued,
            'confirmed': base.filter(status='CONFIRMED').count(),
            'dismissed': base.filter(status='DISMISSED').count(),
        })


class OfficerPerformanceView(APIView):
    """Officer's personal performance metrics."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        officer = request.user
        today    = timezone.now().date()
        week_ago = today - timedelta(days=7)

        base = Violation.objects.filter(officer=officer, source='OFFICER_FIELD')
        today_qs = base.filter(detected_at__date=today)
        week_qs  = base.filter(detected_at__date__gte=week_ago)

        tickets_today = today_qs.count()
        tickets_week  = week_qs.count()
        tickets_total = base.count()
        pending       = base.filter(status__in=['DRAFT', 'SUBMITTED']).count()
        rejected      = base.filter(status='DISMISSED').count()
        confirmed     = base.filter(status='CONFIRMED').count()

        accuracy_pct = round((confirmed / tickets_total * 100) if tickets_total > 0 else 0)

        # Weekly breakdown: last 7 days
        weekly = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            weekly.append(base.filter(detected_at__date=d).count())

        return Response({
            'tickets_today': tickets_today,
            'tickets_week': tickets_week,
            'tickets_total': tickets_total,
            'pending': pending,
            'rejected': rejected,
            'confirmed': confirmed,
            'accuracy_pct': accuracy_pct,
            'weekly': weekly,
        })


class OfficerSearchViolationsView(APIView):
    """Search ALL violations (any officer/source) by plate, driver, type — for officer lookups."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        q        = request.query_params.get('q', '').strip()
        plate    = request.query_params.get('plate', '').strip().upper()
        status_f = request.query_params.get('status')
        severity = request.query_params.get('severity')
        date_from= request.query_params.get('date_from')
        date_to  = request.query_params.get('date_to')

        qs = Violation.objects.select_related('violation_type', 'vehicle', 'intersection', 'officer')

        if plate:
            qs = qs.filter(vehicle__plate_number__icontains=plate)
        if q:
            qs = qs.filter(
                Q(vehicle__plate_number__icontains=q) |
                Q(driver_name__icontains=q) |
                Q(driver_license__icontains=q) |
                Q(violation_type__name__icontains=q)
            )
        if status_f:
            qs = qs.filter(status=status_f)
        if severity:
            qs = qs.filter(severity=severity)
        if date_from:
            qs = qs.filter(detected_at__date__gte=date_from)
        if date_to:
            qs = qs.filter(detected_at__date__lte=date_to)

        from itms_backend.pagination import StandardPagination
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs.order_by('-detected_at'), request)
        return paginator.get_paginated_response(
            ViolationSerializer(page, many=True, context={'request': request}).data
        )


class OfficerUpdateProfileView(APIView):
    """Officer update own profile (name, phone) and change password."""
    permission_classes = [IsOfficerOrAbove]

    def get(self, request):
        from accounts.serializers import UserSerializer
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        user = request.user
        full_name = request.data.get('full_name')
        phone     = request.data.get('phone_number')
        email     = request.data.get('email')

        if full_name:
            user.full_name = full_name
        if phone:
            user.phone_number = phone
        if email:
            user.email = email
        user.save()

        # Change password if provided
        old_pw  = request.data.get('old_password')
        new_pw  = request.data.get('new_password')
        if old_pw and new_pw:
            if not user.check_password(old_pw):
                return Response({'error': 'Current password is incorrect.'}, status=400)
            user.set_password(new_pw)
            user.save()

        from accounts.serializers import UserSerializer
        return Response(UserSerializer(user).data)


# ── Supervisor Views ──────────────────────────────────────────────────────
class PendingTicketsView(generics.ListAPIView):
    permission_classes = [IsSupervisorOrAbove]
    serializer_class = ViolationSerializer

    def get_queryset(self):
        return Violation.objects.filter(
            source='OFFICER_FIELD', status='SUBMITTED'
        ).select_related('violation_type', 'vehicle', 'officer', 'intersection').order_by('-created_at')


class ValidateTicketView(APIView):
    permission_classes = [IsSupervisorOrAbove]

    def post(self, request, pk):
        try:
            violation = Violation.objects.get(pk=pk, status='SUBMITTED')
        except Violation.DoesNotExist:
            return Response({'error': 'Ticket not found or not pending.'}, status=404)

        decision = request.data.get('decision')
        feedback = request.data.get('feedback', '')

        if decision not in ('APPROVE', 'REJECT'):
            return Response({'error': 'decision must be APPROVE or REJECT'}, status=400)

        old_status = violation.status
        if decision == 'APPROVE':
            violation.status = 'CONFIRMED'
        else:
            violation.status = 'DISMISSED'
            violation.notes = f'[REJECTED by supervisor: {feedback}]\n{violation.notes}'
        violation.save()

        ViolationStatusHistory.objects.create(
            violation=violation, old_status=old_status,
            new_status=violation.status, changed_by=request.user, reason=feedback
        )

        if decision == 'APPROVE':
            _create_fine_for_violation(violation)

        return Response({'message': f'Ticket {violation.status.lower()}.', 'status': violation.status})


class SupervisorOfficersView(APIView):
    permission_classes = [IsSupervisorOrAbove]

    def get(self, request):
        from accounts.models import CustomUser
        officers = CustomUser.objects.filter(
            role__in=['OFFICER'], is_active=True
        ).select_related('profile')

        today = timezone.now().date()
        officer_data = []
        for officer in officers:
            officer_data.append({
                'id': str(officer.id),
                'full_name': officer.full_name,
                'badge_number': officer.badge_number,
                'assigned_zone': getattr(getattr(officer, 'profile', None), 'assigned_zone', None),
                'tickets_count': Violation.objects.filter(officer=officer).count(),
                'tickets_today': Violation.objects.filter(officer=officer, detected_at__date=today).count(),
            })
        return Response({'count': len(officer_data), 'results': officer_data})


class SupervisorDailyReportView(APIView):
    permission_classes = [IsSupervisorOrAbove]

    def get(self, request):
        today = timezone.now().date()
        return Response({
            'tickets_issued': Violation.objects.filter(
                source='OFFICER_FIELD', detected_at__date=today
            ).count(),
            'fines_generated': Fine.objects.filter(created_at__date=today).count(),
            'escalated': Violation.objects.filter(
                source='OFFICER_FIELD', status='ESCALATED', detected_at__date=today
            ).count(),
            'sync_failures': 0,  # Could track from log
            'total': Violation.objects.filter(detected_at__date=today).count(),
        })


# ── Helpers ───────────────────────────────────────────────────────────────
def _create_fine_for_violation(violation):
    """Create a Fine record for a confirmed/submitted violation if one doesn't exist."""
    from django.utils import timezone
    from fines.models import Fine, FineRule
    from datetime import timedelta

    if Fine.objects.filter(violation=violation).exists():
        return

    owner = violation.vehicle.owner
    if not owner:
        return

    rule = FineRule.objects.filter(
        violation_type=violation.violation_type,
        severity=violation.severity,
        is_active=True
    ).order_by('-effective_from').first()

    amount = rule.amount if rule else 500  # Default fine

    Fine.objects.create(
        violation=violation,
        citizen=owner,
        amount=amount,
        status='UNPAID',
        due_date=timezone.now().date() + timedelta(days=30),
    )

    # Update compliance score
    try:
        owner.profile.recalculate_compliance_score()
    except Exception:
        pass


def _broadcast_new_violation(violation):
    """Push to ws/violations/feed/ channel."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)('violations_feed', {
            'type': 'new_violation',
            'data': {
                'violation_id': str(violation.id),
                'type': violation.violation_type.code,
                'plate': violation.vehicle.plate_number,
                'severity': violation.severity,
                'source': violation.source,
                'location': violation.intersection.name if violation.intersection else None,
            }
        })
    except Exception:
        pass


def _broadcast_officer_sync(officer, violation, sync_status):
    """Push sync confirmation to officer's WebSocket."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'officer_sync_{officer.id}',
            {'type': 'sync_update', 'data': {
                'ticket_id': str(violation.id),
                'status': sync_status,
                'message': f'Ticket {sync_status} successfully.'
            }}
        )
    except Exception:
        pass
