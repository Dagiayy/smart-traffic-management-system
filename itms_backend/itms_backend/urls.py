"""
ITMS Backend URL Configuration
All APIs under /api/v1/ prefix
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # ── Authentication (shared by all clients) ─────────────────────────
    path('api/v1/auth/', include('accounts.urls')),

    # ── Citizen App ────────────────────────────────────────────────────
    path('api/v1/citizen/', include('accounts.citizen_urls')),

    # ── Officer / Supervisor App ───────────────────────────────────────
    path('api/v1/officer/', include('violations.officer_urls')),
    path('api/v1/supervisor/', include('violations.supervisor_urls')),

    # ── Admin Panel ────────────────────────────────────────────────────
    path('api/v1/admin/', include('accounts.admin_urls')),

    # ── Developer Panel ────────────────────────────────────────────────
    path('api/v1/dev/', include('ai_brain.dev_urls')),

    # ── AI Brain Service ───────────────────────────────────────────────
    path('api/v1/ai/', include('ai_brain.urls')),

    # ── Intersections (shared) ─────────────────────────────────────────
    path('api/v1/', include('intersections.urls')),

    # ── Vehicles (officer lookup) ──────────────────────────────────────
    path('api/v1/', include('vehicles.urls')),

    # ── Notifications (officer + shared) ──────────────────────────────
    path('api/v1/officer/', include('notifications.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Customize admin site
admin.site.site_header = 'ITMS Administration'
admin.site.site_title = 'ITMS Admin'
admin.site.index_title = 'Intelligent Traffic Management System'
