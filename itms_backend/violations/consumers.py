"""violations/consumers.py — WebSocket for live violation feed"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer


class ViolationFeedConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_name = 'violations_feed'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def new_violation(self, event):
        await self.send(text_data=json.dumps({'type': 'new_violation', 'data': event['data']}))
