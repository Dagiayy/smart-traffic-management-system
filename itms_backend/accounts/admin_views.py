"""
accounts/admin_views.py — Admin Panel API views
"""
from django.db.models import Count, Sum, Q
from django.utils import timezone
from datetime import timedelta
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import filters

from itms_backend.permissions import IsAdmin, IsAdminOrDeveloper
from .models import CustomUser, UserProfile
from .serializers import UserSerializer, CreateUserSerializer, UpdateUserSerializer


class AdminDashboardSummaryView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from violations.models import Violation
        from fines.models import Fine
        from intersections.models import Intersection
        from ai_brain.models import AIAlert, CongestedZone

        today = timezone.now().date()
        return Response({
            'total_violations_today': Violation.objects.filter(detected_at__date=today).count(),
            'total_violations_week': Violation.objects.filter(
                detected_at__date__gte=today - timedelta(days=7)
            ).count(),
            'fines_collected_today': Fine.objects.filter(
                status='PAID', updated_at__date=today
            ).aggregate(total=Sum('amount'))['total'] or 0,
            'fines_collected_total': Fine.objects.filter(
                status='PAID'
            ).aggregate(total=Sum('amount'))['total'] or 0,
            'active_intersections': Intersection.objects.filter(is_active=True).count(),
            'total_users': CustomUser.objects.filter(is_active=True).count(),
            'active_officers': CustomUser.objects.filter(
                role__in=['OFFICER', 'SUPERVISOR'], is_active=True
            ).count(),
            'alerts_count': AIAlert.objects.filter(resolved_at__isnull=True).count(),
            'ai_status': 'ACTIVE',  # Would check AI session status
            'congested_zones': CongestedZone.objects.filter(resolved_at__isnull=True).count(),
        })


class AdminViolationAnalyticsView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from violations.models import Violation
        period = request.query_params.get('period', 'week')
        group_by = request.query_params.get('group_by', 'type')

        start_date = {
            'day': timezone.now() - timedelta(days=1),
            'week': timezone.now() - timedelta(days=7),
            'month': timezone.now() - timedelta(days=30),
        }.get(period, timezone.now() - timedelta(days=7))

        qs = Violation.objects.filter(detected_at__gte=start_date)
        total = qs.count()
        confirmed = qs.filter(status='CONFIRMED').count()
        dismissed = qs.filter(status='DISMISSED').count()
        critical = qs.filter(severity='CRITICAL').count()
        major = qs.filter(severity='MAJOR').count()
        minor_count = qs.filter(severity='MINOR').count()

        if group_by == 'type':
            by_type = list(
                qs.values('violation_type__name', 'violation_type__code')
                .annotate(count=Count('id'))
                .order_by('-count')[:10]
            )
            results = [{'name': r['violation_type__name'], 'code': r['violation_type__code'], 'count': r['count']} for r in by_type]
        elif group_by == 'location':
            by_loc = list(
                qs.exclude(intersection__isnull=True)
                .values('intersection__name', 'intersection__latitude', 'intersection__longitude')
                .annotate(count=Count('id'))
                .order_by('-count')[:20]
            )
            results = [{'name': r['intersection__name'], 'lat': r['intersection__latitude'], 'lng': r['intersection__longitude'], 'count': r['count']} for r in by_loc]
        else:
            by_sev = [
                {'name': 'CRITICAL', 'count': critical},
                {'name': 'MAJOR', 'count': major},
                {'name': 'MINOR', 'count': minor_count},
            ]
            results = by_sev

        # Daily breakdown for chart
        daily = []
        for i in range(7):
            day = (timezone.now() - timedelta(days=6 - i)).date()
            daily.append(qs.filter(detected_at__date=day).count())

        return Response({
            'total': total,
            'confirmed': confirmed,
            'dismissed': dismissed,
            'critical': critical,
            'major': major,
            'minor': minor_count,
            'daily': daily,
            'results': results,
        })


class AdminFineAnalyticsView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from fines.models import Fine
        period = request.query_params.get('period', 'week')
        start = {
            'day': timezone.now() - timedelta(days=1),
            'week': timezone.now() - timedelta(days=7),
            'month': timezone.now() - timedelta(days=30),
        }.get(period, timezone.now() - timedelta(days=7))

        fines = Fine.objects.filter(created_at__gte=start)
        collected = Fine.objects.filter(status='PAID', updated_at__gte=start)
        return Response({
            'total_fines': fines.count(),
            'total_collected': collected.aggregate(total=Sum('amount'))['total'] or 0,
            'pending_amount': fines.filter(status='UNPAID').aggregate(total=Sum('amount'))['total'] or 0,
            'collection_rate': (collected.count() / max(fines.count(), 1)) * 100,
        })


class AdminOfficerPerformanceView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from violations.models import Violation
        today = timezone.now().date()
        officers = CustomUser.objects.filter(
            role__in=['OFFICER', 'SUPERVISOR'], is_active=True
        ).select_related('profile')

        officer_data = []
        for officer in officers:
            today_tickets = Violation.objects.filter(
                officer=officer, detected_at__date=today
            ).count()
            week_tickets = Violation.objects.filter(
                officer=officer, detected_at__date__gte=today - timedelta(days=7)
            ).count()
            total_tickets = Violation.objects.filter(officer=officer).count()
            officer_data.append({
                'id': str(officer.id),
                'full_name': officer.full_name,
                'badge_number': officer.badge_number,
                'assigned_zone': getattr(getattr(officer, 'profile', None), 'assigned_zone', None),
                'tickets_today': today_tickets,
                'tickets_week': week_tickets,
                'tickets_total': total_tickets,
                'tickets': total_tickets,
            })

        today_total = Violation.objects.filter(
            source='OFFICER_FIELD', detected_at__date=today
        ).count()
        return Response({
            'tickets_today': today_total,
            'officers': officer_data,
            'weekly': [Violation.objects.filter(
                source='OFFICER_FIELD',
                detected_at__date=today - timedelta(days=6 - i)
            ).count() for i in range(7)],
        })


class AdminComplianceView(APIView):
    permission_classes = [IsAdminOrDeveloper]

    def get(self, request):
        from django.db.models import Avg
        avg = UserProfile.objects.filter(user__role='CITIZEN').aggregate(
            avg_score=Avg('compliance_score'))['avg_score'] or 100
        safe_count = UserProfile.objects.filter(driver_status='SAFE').count()
        warning_count = UserProfile.objects.filter(driver_status='WARNING').count()
        risk_count = UserProfile.objects.filter(driver_status='HIGH_RISK').count()
        return Response({
            'city_compliance_score': round(avg, 1),
            'safe_drivers': safe_count,
            'warning_drivers': warning_count,
            'high_risk_drivers': risk_count,
        })


# ── User Management ─────────────────────────────────────────────────────
class AdminUsersListView(generics.ListCreateAPIView):
    permission_classes = [IsAdmin]

    def get_serializer_class(self):
        return CreateUserSerializer if self.request.method == 'POST' else UserSerializer

    def get_queryset(self):
        qs = CustomUser.objects.select_related('profile').order_by('-created_at')
        role = self.request.query_params.get('role')
        if role:
            qs = qs.filter(role=role)
        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(Q(full_name__icontains=search) | Q(email__icontains=search) | Q(badge_number__icontains=search))
        return qs

    def create(self, request, *args, **kwargs):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class AdminUserDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAdmin]
    queryset = CustomUser.objects.select_related('profile')

    def get_serializer_class(self):
        return UpdateUserSerializer if self.request.method in ('PUT', 'PATCH') else UserSerializer

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()
        serializer = UpdateUserSerializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data)


# ── Disputes management ────────────────────────────────────────────────
class AdminDisputesListView(generics.ListAPIView):
    permission_classes = [IsAdmin]

    def get_queryset(self):
        from disputes.models import Dispute
        qs = Dispute.objects.select_related('violation', 'citizen', 'decision').order_by('-submitted_at')
        status_f = self.request.query_params.get('status')
        if status_f:
            qs = qs.filter(status=status_f)
        return qs

    def get_serializer_class(self):
        from disputes.serializers import DisputeDetailSerializer
        return DisputeDetailSerializer


class AdminDisputeDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAdmin]

    def get_queryset(self):
        from disputes.models import Dispute
        return Dispute.objects.select_related('violation', 'citizen', 'decision')

    def get_serializer_class(self):
        from disputes.serializers import DisputeDetailSerializer
        return DisputeDetailSerializer


class AdminDisputeDecideView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request, pk):
        from disputes.models import Dispute, DisputeDecision
        try:
            dispute = Dispute.objects.get(pk=pk)
        except Dispute.DoesNotExist:
            return Response({'error': 'Dispute not found.'}, status=status.HTTP_404_NOT_FOUND)

        decision = request.data.get('decision')
        if decision not in ('APPROVE', 'REJECT'):
            return Response({'error': 'Invalid decision.'}, status=status.HTTP_400_BAD_REQUEST)

        DisputeDecision.objects.update_or_create(
            dispute=dispute,
            defaults={
                'decided_by': request.user,
                'decision': decision,
                'reason': request.data.get('reason', ''),
            }
        )
        dispute.status = 'APPROVED' if decision == 'APPROVE' else 'REJECTED'
        dispute.resolved_at = timezone.now()
        dispute.save()

        # If approved, dismiss the violation
        if decision == 'APPROVE':
            dispute.violation.status = 'DISMISSED'
            dispute.violation.save()
            # Waive fine if exists
            from fines.models import Fine
            Fine.objects.filter(violation=dispute.violation).update(
                status='WAIVED', waive_reason='Dispute approved by admin'
            )

        # Notify citizen
        from notifications.models import Notification
        Notification.objects.create(
            user=dispute.citizen,
            title='Dispute Update',
            message=f'Your dispute has been {"approved" if decision == "APPROVE" else "rejected"}.',
            notification_type='DISPUTE_UPDATE',
        )

        return Response({'status': dispute.status, 'message': 'Decision recorded.'})


# ── System settings ────────────────────────────────────────────────────
class AdminSettingsView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        # Return system configuration
        return Response({
            'system_name': 'ITMS - Intelligent Traffic Management System',
            'city': 'Addis Ababa',
            'currency': 'ETB',
            'compliance_deduction_per_violation': 10,
            'max_disputes_per_citizen': 5,
            'fine_payment_deadline_days': 30,
            'otp_expiry_minutes': 10,
        })

    def put(self, request):
        # In production, persist to a settings model
        return Response({'message': 'Settings updated.', 'settings': request.data})
