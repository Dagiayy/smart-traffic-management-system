"""notifications/tasks.py — Async notification tasks via Celery"""
import logging
from celery import shared_task
from django.utils import timezone
from datetime import timedelta

logger = logging.getLogger(__name__)


@shared_task
def send_push_notification(user_id, title, message, data=None):
    """Send FCM push notification to all user devices."""
    from accounts.models import PushToken
    from django.conf import settings

    tokens = list(PushToken.objects.filter(user_id=user_id, is_active=True).values_list('token', flat=True))
    if not tokens or not settings.FCM_SERVER_KEY:
        logger.info(f'[PUSH] No tokens or FCM key for user {user_id}: {title}')
        return

    # FCM push (simplified — use firebase-admin in production)
    import requests
    headers = {
        'Authorization': f'key={settings.FCM_SERVER_KEY}',
        'Content-Type': 'application/json',
    }
    payload = {
        'registration_ids': tokens,
        'notification': {'title': title, 'body': message},
        'data': data or {},
    }
    try:
        resp = requests.post('https://fcm.googleapis.com/fcm/send', json=payload, headers=headers, timeout=10)
        logger.info(f'[PUSH] Sent to user {user_id}: {resp.status_code}')
    except Exception as e:
        logger.error(f'[PUSH] Error for user {user_id}: {e}')


@shared_task
def notify_fine_due_reminders():
    """Daily task: notify citizens about fines due in 3 days."""
    from fines.models import Fine
    from notifications.models import Notification

    due_soon = Fine.objects.filter(
        status='UNPAID',
        due_date=timezone.now().date() + timedelta(days=3)
    ).select_related('citizen', 'violation')

    for fine in due_soon:
        Notification.objects.get_or_create(
            user=fine.citizen,
            notification_type='FINE_DUE',
            data={'fine_id': str(fine.id)},
            defaults={
                'title': 'Fine Due Soon',
                'message': f'Your fine of ETB {fine.amount} is due in 3 days.',
            }
        )
        send_push_notification.delay(
            str(fine.citizen.id),
            'Fine Due Reminder',
            f'ETB {fine.amount} due in 3 days for {fine.violation.violation_type.name}',
            {'fine_id': str(fine.id), 'type': 'FINE_DUE'}
        )


@shared_task
def cleanup_old_notifications():
    """Weekly task: delete read notifications older than 30 days."""
    from notifications.models import Notification
    cutoff = timezone.now() - timedelta(days=30)
    deleted, _ = Notification.objects.filter(is_read=True, created_at__lt=cutoff).delete()
    logger.info(f'[CLEANUP] Deleted {deleted} old notifications')


@shared_task
def update_compliance_scores():
    """Daily task: recalculate all citizen compliance scores."""
    from accounts.models import UserProfile
    profiles = UserProfile.objects.filter(user__role='CITIZEN')
    for profile in profiles:
        try:
            profile.recalculate_compliance_score()
        except Exception as e:
            logger.error(f'[COMPLIANCE] Error for profile {profile.id}: {e}')
    logger.info(f'[COMPLIANCE] Updated {profiles.count()} scores')
