from django.urls import path
from .officer_views import (
    OfficerTicketsView, OfficerTicketDetailView, SubmitTicketView,
    BulkSyncView, PlateLookupView, ViolationTypesView,
)

urlpatterns = [
    path('tickets/',                OfficerTicketsView.as_view()),
    path('tickets/bulk-sync/',      BulkSyncView.as_view()),
    path('tickets/<uuid:pk>/',      OfficerTicketDetailView.as_view()),
    path('tickets/<uuid:pk>/submit/', SubmitTicketView.as_view()),
    path('plate-lookup/',           PlateLookupView.as_view()),
    path('violation-types/',        ViolationTypesView.as_view()),
]
