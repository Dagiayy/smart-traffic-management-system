from django.contrib import admin
from .models import AISession, RLEpisode, SignalDecision, CongestedZone, AIAlert, ExperimentConfig

@admin.register(AISession)
class AISessionAdmin(admin.ModelAdmin):
    list_display = ['name', 'scenario_id', 'status', 'started_at', 'total_episodes']
    list_filter = ['status']

@admin.register(AIAlert)
class AIAlertAdmin(admin.ModelAdmin):
    list_display = ['alert_type', 'severity', 'message', 'created_at']
    list_filter = ['alert_type', 'severity']

admin.site.register(RLEpisode)
admin.site.register(SignalDecision)
admin.site.register(CongestedZone)
admin.site.register(ExperimentConfig)
