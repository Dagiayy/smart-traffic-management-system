from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, UserProfile, OTPVerification, PushToken

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'full_name', 'email', 'role', 'is_active', 'created_at']
    list_filter = ['role', 'is_active']
    search_fields = ['username', 'email', 'full_name', 'badge_number']
    fieldsets = UserAdmin.fieldsets + (('ITMS Fields', {'fields': ('full_name', 'role', 'phone_number', 'national_id', 'badge_number')}),)

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'compliance_score', 'driver_status', 'assigned_zone']
    list_filter = ['driver_status']

admin.site.register(PushToken)
admin.site.register(OTPVerification)
