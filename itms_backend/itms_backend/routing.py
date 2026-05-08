from django.urls import re_path
from intersections import consumers as traffic_consumers
from violations import consumers as violation_consumers
from ai_brain import consumers as ai_consumers
from notifications import consumers as notif_consumers

websocket_urlpatterns = [
    # Live traffic signal state for admin panel
    re_path(r'ws/traffic/(?P<intersection_id>[^/]+)/$', traffic_consumers.TrafficConsumer.as_asgi()),

    # Real-time violation feed for admin panel
    re_path(r'ws/violations/feed/$', violation_consumers.ViolationFeedConsumer.as_asgi()),

    # RL training metrics for developer panel
    re_path(r'ws/ai/session/(?P<session_id>[^/]+)/$', ai_consumers.AISessionConsumer.as_asgi()),

    # System-wide alerts (admin + dev panel)
    re_path(r'ws/alerts/$', notif_consumers.AlertsConsumer.as_asgi()),

    # Officer sync confirmations
    re_path(r'ws/officer/sync/(?P<officer_id>[^/]+)/$', notif_consumers.OfficerSyncConsumer.as_asgi()),
]
