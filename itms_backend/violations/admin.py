from django.contrib import admin
from .models import ViolationType, Violation, ViolationEvidence

@admin.register(ViolationType)
class ViolationTypeAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'default_severity', 'is_active']
    list_filter = ['default_severity', 'is_active']
    search_fields = ['code', 'name']

@admin.register(Violation)
class ViolationAdmin(admin.ModelAdmin):
    list_display = ['id', 'violation_type', 'vehicle', 'source', 'status', 'severity', 'detected_at']
    list_filter = ['source', 'status', 'severity']
    search_fields = ['vehicle__plate_number', 'officer__full_name']
    date_hierarchy = 'detected_at'

admin.site.register(ViolationEvidence)
