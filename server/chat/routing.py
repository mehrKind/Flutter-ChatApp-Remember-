# chat/routing.py
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<room_id>\d+)/(?P<phoneNumber>[\w.@+-]+)/$', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/chat-list/(?P<user_id>\w+)/$', consumers.ChatListConsumer.as_asgi()),
    # re_path(r'ws/notif/(?P<phoneNumber>[\w.@+-]+)/$', consumers.NotificationConsumer.as_asgi()),
]