from django.contrib import admin
from .models import FineRule, Fine, Payment, Receipt

@admin.register(FineRule)
class FineRuleAdmin(admin.ModelAdmin):
    list_display = ['violation_type', 'severity', 'amount', 'is_active', 'effective_from']
    list_filter = ['severity', 'is_active']

@admin.register(Fine)
class FineAdmin(admin.ModelAdmin):
    list_display = ['id', 'citizen', 'amount', 'status', 'due_date', 'created_at']
    list_filter = ['status']
    search_fields = ['citizen__full_name', 'citizen__phone_number']

admin.site.register(Payment)
admin.site.register(Receipt)
