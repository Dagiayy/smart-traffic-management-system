"""
itms_backend/exceptions.py — Custom exception handler returning { error, code, details }
itms_backend/permissions.py — Role-based permission classes
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status, permissions


# ── Exception Handler ─────────────────────────────────────────────────────
def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        error_data = {
            'error': str(exc),
            'code': _get_error_code(response.status_code),
            'details': {},
        }
        # Try to extract DRF validation errors
        if isinstance(response.data, dict):
            if 'detail' in response.data:
                error_data['error'] = str(response.data['detail'])
            elif any(isinstance(v, list) for v in response.data.values()):
                error_data['details'] = {
                    k: v if not isinstance(v, list) else v[0] if len(v) == 1 else v
                    for k, v in response.data.items()
                }
                error_data['error'] = 'Validation failed'
                error_data['code'] = 'VALIDATION_ERROR'
        response.data = error_data
    return response


def _get_error_code(status_code):
    return {
        400: 'BAD_REQUEST',
        401: 'UNAUTHORIZED',
        403: 'FORBIDDEN',
        404: 'NOT_FOUND',
        405: 'METHOD_NOT_ALLOWED',
        409: 'CONFLICT',
        422: 'VALIDATION_ERROR',
        500: 'SERVER_ERROR',
    }.get(status_code, 'ERROR')


# ── Permission Classes ─────────────────────────────────────────────────────
class IsCitizen(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'CITIZEN')


class IsOfficerOrAbove(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and request.user.role in ('OFFICER', 'SUPERVISOR', 'ADMIN'))


class IsSupervisorOrAbove(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and request.user.role in ('SUPERVISOR', 'ADMIN'))


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'ADMIN')


class IsAdminOrDeveloper(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and request.user.role in ('ADMIN', 'DEVELOPER'))


class IsAIService(permissions.BasePermission):
    """Used for AI Brain service endpoints — checked via X-AI-Service-Key header"""
    def has_permission(self, request, view):
        from django.conf import settings
        key = request.META.get('HTTP_X_AI_SERVICE_KEY', '')
        return key == settings.AI_SERVICE_KEY
