"""
accounts/authentication.py — Custom authenticator for AI Brain service key
"""
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from django.conf import settings


class AIServiceKeyAuthentication(BaseAuthentication):
    """
    AI Brain service authenticates with X-AI-Service-Key header
    instead of a user JWT token.
    """
    def authenticate(self, request):
        key = request.META.get('HTTP_X_AI_SERVICE_KEY', '')
        if not key:
            return None  # Not this auth method — try next

        if key != settings.AI_SERVICE_KEY:
            raise AuthenticationFailed('Invalid AI service key.')

        # Return a pseudo-user tuple (user=None, auth=key)
        # Views must check for IsAIService permission
        return (None, key)

    def authenticate_header(self, request):
        return 'X-AI-Service-Key'
