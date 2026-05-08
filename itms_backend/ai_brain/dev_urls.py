"""ai_brain/dev_urls.py — Developer panel endpoints"""
from django.urls import path
from .dev_views import (
    DevAISessionsView, DevAISessionDetailView, DevStopSessionView,
    DevSessionEpisodesView, DevExperimentsView,
    DevScenariosView, DevScenarioReplayView,
    DevSystemLogsView, DevPerformanceComparisonView, DevRLParamsView,
)

urlpatterns = [
    path('ai-sessions/',                          DevAISessionsView.as_view()),
    path('ai-sessions/<uuid:pk>/',               DevAISessionDetailView.as_view()),
    path('ai-sessions/<uuid:pk>/stop/',          DevStopSessionView.as_view()),
    path('ai-sessions/<uuid:pk>/episodes/',      DevSessionEpisodesView.as_view()),
    path('experiments/',                          DevExperimentsView.as_view()),
    path('scenarios/',                            DevScenariosView.as_view()),
    path('scenarios/<str:pk>/replay/',           DevScenarioReplayView.as_view()),
    path('system-logs/',                          DevSystemLogsView.as_view()),
    path('performance-comparison/',               DevPerformanceComparisonView.as_view()),
    path('rl-params/',                            DevRLParamsView.as_view()),
]
