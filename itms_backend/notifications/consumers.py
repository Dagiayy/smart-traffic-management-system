"""notifications/consumers.py"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer


class AlertsConsumer(AsyncWebsocketConsumer):
    """System-wide alerts for admin and developer panels."""
    async def connect(self):
        self.group_name = 'alerts'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def alert_message(self, event):
        await self.send(text_data=json.dumps({'type': 'alert', 'data': event['data']}))


class OfficerSyncConsumer(AsyncWebsocketConsumer):
    """Sync confirmations for officer Flutter app."""
    async def connect(self):
        self.officer_id = self.scope['url_route']['kwargs']['officer_id']
        self.group_name = f'officer_sync_{self.officer_id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def sync_update(self, event):
        await self.send(text_data=json.dumps({'type': 'sync_update', 'data': event['data']}))
