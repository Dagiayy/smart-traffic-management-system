from django.urls import path
from .officer_views import (
    PendingTicketsView, ValidateTicketView,
    SupervisorOfficersView, SupervisorDailyReportView,
)

urlpatterns = [
    path('tickets/pending/',            PendingTicketsView.as_view()),
    path('tickets/<uuid:pk>/validate/', ValidateTicketView.as_view()),
    path('officers/',                   SupervisorOfficersView.as_view()),
    path('reports/daily/',              SupervisorDailyReportView.as_view()),
]
