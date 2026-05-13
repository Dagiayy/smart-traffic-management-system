"""Citizen app URLs"""
from django.urls import path
from .citizen_views import (
    CitizenViolationsView, CitizenViolationDetailView, CitizenViolationSummaryView,
    CitizenFinesView, CitizenFineDetailView, PayFineView,
    CitizenReceiptsView, CitizenReceiptDetailView,
    CitizenDisputesView, CitizenDisputeDetailView,
    CitizenVehiclesView, CitizenVehicleDetailView,
    CitizenTrafficAlertsView,
    CitizenNotificationsView, MarkNotificationReadView,
    ChapaInitiateView, ChapaVerifyView, ChapaCallbackView,
    CitizenProfileView,
)

urlpatterns = [
    # Violations
    path('violations/',                         CitizenViolationsView.as_view()),
    path('violations/summary/',                 CitizenViolationSummaryView.as_view()),
    path('violations/<uuid:pk>/',               CitizenViolationDetailView.as_view()),

    # Fines & Payments
    path('fines/',                              CitizenFinesView.as_view()),
    path('fines/<uuid:pk>/',                    CitizenFineDetailView.as_view()),
    path('fines/<uuid:pk>/pay/',                PayFineView.as_view()),
    path('fines/<uuid:pk>/chapa/initiate/',     ChapaInitiateView.as_view()),
    path('fines/<uuid:pk>/chapa/verify/',       ChapaVerifyView.as_view()),
    path('receipts/',                           CitizenReceiptsView.as_view()),
    path('receipts/<uuid:pk>/',                 CitizenReceiptDetailView.as_view()),

    # Chapa callback (webhook from Chapa)
    path('chapa/callback/',                     ChapaCallbackView.as_view()),

    # Disputes
    path('disputes/',                           CitizenDisputesView.as_view()),
    path('disputes/<uuid:pk>/',                 CitizenDisputeDetailView.as_view()),

    # Vehicles
    path('vehicles/',                           CitizenVehiclesView.as_view()),
    path('vehicles/<uuid:pk>/',                 CitizenVehicleDetailView.as_view()),

    # Traffic alerts (congestion zones)
    path('traffic-alerts/',                     CitizenTrafficAlertsView.as_view()),

    # Notifications
    path('notifications/',                      CitizenNotificationsView.as_view()),
    path('notifications/<uuid:pk>/read/',       MarkNotificationReadView.as_view()),

    # Profile
    path('profile/',                            CitizenProfileView.as_view()),
]
