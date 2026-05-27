from django.urls import path
from . import views

urlpatterns = [
    path("all_chats", views.UserChatListView.as_view(), name="UserChatListView"),
    path('start-or-get-room', views.StartOrGetRoomView.as_view(), name='start_or_get_room'),
    path("chat_history/", views.AllMessagesView.as_view(), name="chat_history")
]


