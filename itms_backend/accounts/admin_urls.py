"""Admin panel URLs"""
from django.urls import path
from .admin_views import (
    AdminDashboardSummaryView,
    AdminViolationAnalyticsView, AdminFineAnalyticsView,
    AdminOfficerPerformanceView, AdminComplianceView,
    AdminUsersListView, AdminUserDetailView,
    AdminDisputesListView, AdminDisputeDetailView, AdminDisputeDecideView,
    AdminSettingsView,
)
from violations.admin_views import (
    AdminViolationsListView, AdminViolationDetailView,
    AdminEvidenceListView, AdminEvidenceDetailView,
    AdminHotspotMapView,
)
from fines.admin_views import (
    AdminFinesListView, AdminFineDetailView,
    AdminFineRulesView, AdminFineRuleDetailView,
)
from intersections.admin_views import (
    AdminIntersectionsListView, AdminIntersectionDetailView,
    AdminManualOverrideView,
)

urlpatterns = [
    # Dashboard & Analytics
    path('dashboard/summary/',            AdminDashboardSummaryView.as_view()),
    path('analytics/violations/',         AdminViolationAnalyticsView.as_view()),
    path('analytics/fines/',              AdminFineAnalyticsView.as_view()),
    path('analytics/compliance/',         AdminComplianceView.as_view()),
    path('analytics/officer-performance/', AdminOfficerPerformanceView.as_view()),

    # Violations
    path('violations/',                   AdminViolationsListView.as_view()),
    path('violations/<uuid:pk>/',         AdminViolationDetailView.as_view()),
    path('evidence/',                     AdminEvidenceListView.as_view()),
    path('evidence/<uuid:pk>/',           AdminEvidenceDetailView.as_view()),
    path('hotspot-map/',                  AdminHotspotMapView.as_view()),

    # Fines
    path('fines/',                        AdminFinesListView.as_view()),
    path('fines/<uuid:pk>/',              AdminFineDetailView.as_view()),
    path('fine-rules/',                   AdminFineRulesView.as_view()),
    path('fine-rules/<uuid:pk>/',         AdminFineRuleDetailView.as_view()),

    # Traffic control
    path('intersections/',                AdminIntersectionsListView.as_view()),
    path('intersections/<uuid:pk>/',      AdminIntersectionDetailView.as_view()),
    path('intersections/<uuid:pk>/manual-override/', AdminManualOverrideView.as_view()),

    # Disputes
    path('disputes/',                     AdminDisputesListView.as_view()),
    path('disputes/<uuid:pk>/',           AdminDisputeDetailView.as_view()),
    path('disputes/<uuid:pk>/decide/',    AdminDisputeDecideView.as_view()),

    # User management
    path('users/',                        AdminUsersListView.as_view()),
    path('users/<uuid:pk>/',              AdminUserDetailView.as_view()),

    # Settings
    path('settings/',                     AdminSettingsView.as_view()),
]
