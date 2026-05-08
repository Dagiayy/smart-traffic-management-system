"""intersections/consumers.py — Live traffic signal WebSocket"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer


class TrafficConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.intersection_id = self.scope['url_route']['kwargs']['intersection_id']
        self.group_name = f'traffic_{self.intersection_id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        pass  # Read-only channel — no client messages

    async def signal_update(self, event):
        await self.send(text_data=json.dumps({'type': 'signal_update', 'data': event['data']}))
