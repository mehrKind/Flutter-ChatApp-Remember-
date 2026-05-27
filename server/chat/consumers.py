import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import ChatRoom, Message
from accounts.models import UserProfile

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.phone_number = self.scope['url_route']['kwargs']['phoneNumber']
        self.room_group_name = f'chat_{self.room_id}'

        print(f"[CONNECT] Phone: {self.phone_number}, Room: {self.room_id}")

        if await self.verify_user_access():
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            await self.accept()
            print(f"[CONNECTED] {self.phone_number} joined room {self.room_id}")
        else:
            print(f"[DENIED] Access denied for {self.phone_number}")
            await self.close()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        print(f"[DISCONNECTED] {self.phone_number} from room {self.room_id}")

    async def receive(self, text_data):
        try:
            print(f"[RECEIVE] {text_data}")
            data = json.loads(text_data)
            action = data.get('action')
            

            if action == 'seen':
                await self.handle_seen_action(data)
            else:
                await self.handle_text_message(data)
        except Exception as e:
            print(f"[ERROR] In receive: {e}")
            await self.close()

    async def handle_seen_action(self, data):
        try:
            await self.mark_as_seen(data["message_id"])
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "seen_message",
                    "message_id": data["message_id"],
                    "sender_phone": self.phone_number
                }
            )
        except Exception as e:
            print(f"[ERROR] In handle_seen_action: {e}")

    async def handle_text_message(self, data):
        try:
            message_obj, sender_id = await self.save_text_message(data)

            # Get message preview for broadcast
            user_profile = await database_sync_to_async(UserProfile.objects.get)(user__id=sender_id)
            message_data = await self.format_message_response(message_obj, user_profile)

            # Send to chat room
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "chat_message",
                    "message": message_data,
                    "sender_phone": self.phone_number
                }
            )

            # Get recipient
            room = await database_sync_to_async(ChatRoom.objects.get)(id=self.room_id)
            recipient_id = await self.get_recipient_id(room, sender_id)

            # Send to recipient’s chat list
            await self.channel_layer.group_send(
                f"chat_list_{recipient_id}",
                {
                    "type": "chat_list_update",
                    "data": await self.format_message_preview(message_obj)
                }
            )

        except Exception as e:
            print(f"[ERROR] In handle_text_message: {e}")
            await self.close()


    async def chat_message(self, event):
        try:
            await self.send(text_data=json.dumps({
                "message": event["message"],
                "sender_phone": event["sender_phone"]
            }))
        except Exception as e:
            print(f"[ERROR] In chat_message send: {e}")

    async def seen_message(self, event):
        try:
            await self.send(text_data=json.dumps({
                "message_id": event["message_id"],
                "sender_phone": event["sender_phone"]
            }))
        except Exception as e:
            print(f"[ERROR] In seen_message send: {e}")
            
    async def chat_list_update(self, event):
        try:
            await self.send(text_data=json.dumps(event["data"]))
        except Exception as e:
            print(f"[ERROR] In chat_list_update: {e}")

    @database_sync_to_async
    def format_message_preview(self, message):
        return {
            "room_id": message.chat_room.id,
            "content": message.content,
            "timestamp": str(message.timestamp),
            "sender": {
                "username": message.sender.username,
                "phone_number": message.sender.profile.phone_number,
                "profile_picture": message.sender.profile.profile_picture.url if message.sender.profile.profile_picture else None,
            }
        }


    @database_sync_to_async
    def verify_user_access(self):
        try:
            user_profile = UserProfile.objects.get(phone_number=self.phone_number)
            room = ChatRoom.objects.get(id=self.room_id)
            return user_profile.user in room.participants.all()
        except (UserProfile.DoesNotExist, ChatRoom.DoesNotExist):
            return False

    @database_sync_to_async
    def save_text_message(self, data):
        user_profile = UserProfile.objects.get(phone_number=self.phone_number)
        room = ChatRoom.objects.get(id=self.room_id)

        message = Message.objects.create(
            chat_room=room,
            sender=user_profile.user,
            content=data.get('message'),
            is_deleted=False
        )

        return message, user_profile.user.id



    @database_sync_to_async
    def mark_as_seen(self, message_id):
        try:
            msg = Message.objects.get(id=message_id)
            msg.seen = True
            msg.save()
        except Message.DoesNotExist:
            pass

    @database_sync_to_async
    def format_message_response(self, message, user, extra_data=None):
        try:
            try:
                parsed_content = json.loads(message.content)
            except (ValueError, TypeError):
                parsed_content = message.content

            return {
                "id": str(message.id),
                "room_id": str(message.chat_room.id),
                "sender": {
                    "username": message.sender.username,
                    "phone_number": message.sender.profile.phone_number,
                    "profile_picture": message.sender.profile.profile_picture.url if message.sender.profile.profile_picture else None,
                },
                "content": parsed_content,
                "timestamp": message.timestamp.isoformat(),
                "seen": message.seen,
                "msg_type": extra_data.get('msg_type', 'text') if extra_data else 'text'
            }
        except Exception as e:
            print(f"[ERROR] In format_message_response: {e}")
            return {"error": "Message formatting failed"}
        
        
    @database_sync_to_async
    def get_recipient_id(self, room, sender_id):
        participant_ids = list(room.participants.all().values_list('id', flat=True))
        return next(uid for uid in participant_ids if uid != sender_id)




class ChatListConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.group_name = f'chat_list_{self.user_id}'

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def chat_list_update(self, event):
        await self.send(text_data=json.dumps(event["data"]))
