from django.urls import path
from .officer_views import (
    OfficerTicketsView, OfficerTicketDetailView, SubmitTicketView,
    BulkSyncView, PlateLookupView, ViolationTypesView,
    OfficerDashboardView, OfficerAnalyticsView,
    OfficerDailyReportView, OfficerPerformanceView,
    OfficerSearchViolationsView, OfficerUpdateProfileView,
    OfficerProfileEditRequestView,
)

urlpatterns = [
    path('tickets/',                    OfficerTicketsView.as_view()),
    path('tickets/bulk-sync/',          BulkSyncView.as_view()),
    path('tickets/<uuid:pk>/',          OfficerTicketDetailView.as_view()),
    path('tickets/<uuid:pk>/submit/',   SubmitTicketView.as_view()),
    path('plate-lookup/',               PlateLookupView.as_view()),
    path('violation-types/',            ViolationTypesView.as_view()),
    path('dashboard/',                  OfficerDashboardView.as_view()),
    path('analytics/',                  OfficerAnalyticsView.as_view()),
    path('reports/daily/',              OfficerDailyReportView.as_view()),
    path('performance/',                OfficerPerformanceView.as_view()),
    path('search/violations/',          OfficerSearchViolationsView.as_view()),
    path('profile/',                    OfficerUpdateProfileView.as_view()),
    path('profile/edit-request/',       OfficerProfileEditRequestView.as_view()),
]
