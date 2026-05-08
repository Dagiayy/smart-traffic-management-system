from django.urls import path
from .views import NotificationsListView, MarkNotificationReadView, MarkAllReadView

urlpatterns = [
    path('notifications/',                 NotificationsListView.as_view()),
    path('notifications/<uuid:pk>/read/',  MarkNotificationReadView.as_view()),
    path('notifications/mark-all-read/',   MarkAllReadView.as_view()),
]
