"""ai_brain/urls.py — AI Brain service endpoints"""
from django.urls import path
from .views import (
    AIIntersectionStateView, AISignalDecisionView, AICVDetectionView,
    AICongestionAlertView, AIEpisodeLogView, AISimulationLogView, AIConfigView,
)

urlpatterns = [
    path('intersections/state/',  AIIntersectionStateView.as_view()),
    path('signal-decision/',      AISignalDecisionView.as_view()),
    path('cv-detection/',         AICVDetectionView.as_view()),
    path('congestion-alert/',     AICongestionAlertView.as_view()),
    path('episode-log/',          AIEpisodeLogView.as_view()),
    path('simulation-log/',       AISimulationLogView.as_view()),
    path('config/',               AIConfigView.as_view()),
]
