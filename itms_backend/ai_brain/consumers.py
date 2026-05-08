"""ai_brain/consumers.py — WebSocket consumers for AI and alerts"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer


class AISessionConsumer(AsyncWebsocketConsumer):
    """Real-time RL training metrics for developer panel."""
    async def connect(self):
        self.session_id = self.scope['url_route']['kwargs']['session_id']
        self.group_name = f'ai_session_{self.session_id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def training_update(self, event):
        await self.send(text_data=json.dumps({'type': 'training_update', 'data': event['data']}))
