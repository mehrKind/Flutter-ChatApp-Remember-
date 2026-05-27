from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import ChatRoom, Message, Attachment
from accounts.models import UserProfile
from django.db.models import Subquery, OuterRef
# from django.contrib.auth.models import User
# from django.db.models import Prefetch
from django.db.models import Q

class UserChatListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            # Get all chat rooms for the current user with the last message
            chat_rooms = ChatRoom.objects.filter(
                participants=request.user
            ).annotate(
                last_message_id=Subquery(
                    Message.objects.filter(
                        chat_room=OuterRef('pk')
                    ).order_by('-timestamp').values('id')[:1]
                )
            ).prefetch_related('participants')

            # Prepare the response data
            chat_list = []
            for room in chat_rooms:
                # Get the other participant (for private chats)
                other_participant = None
                if not room.is_group_chat:
                    other_participant = room.participants.exclude(id=request.user.id).first()
                
                # Get the last message
                last_message = None
                if room.last_message_id:
                    last_message_obj = Message.objects.get(id=room.last_message_id)
                    last_message = {
                        'content': last_message_obj.content,
                        'timestamp': last_message_obj.timestamp,
                        'seen': last_message_obj.seen,
                        'sender_id': last_message_obj.sender.id,
                        'sender_username': last_message_obj.sender.username,
                        'is_deleted': last_message_obj.is_deleted
                    }

                # Get other participant's profile (for private chats)
                other_user_profile = None
                if other_participant:
                    profile = UserProfile.objects.get(user=other_participant)
                    other_user_profile = {
                        'user_id': other_participant.id,
                        'username': other_participant.username,
                        'profile_picture': request.build_absolute_uri(profile.profile_picture.url) if profile.profile_picture else None,
                        'online_status': profile.online_status,
                        'last_online': profile.last_online,
                        'phone_number': profile.phone_number
                    }

                chat_list.append({
                    'chat_room_id': room.id,
                    'name': room.name,
                    'is_group_chat': room.is_group_chat,
                    'last_message': last_message,
                    'other_participant': other_user_profile,
                    'created_at': room.created_at,
                    'updated_at': room.updated_at
                })

            # Sort by last message timestamp (newest first)
            chat_list.sort(key=lambda x: x['last_message']['timestamp'] if x['last_message'] else x['created_at'], reverse=True)

            context = {
                "status": status.HTTP_200_OK,
                "data": chat_list,
                "error": None
            }

            return Response(context)

        except Exception as e:
            context = {
                "status": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "data": None,
                "error": str(e)
            }
            return Response(context, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        

class StartOrGetRoomView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        phone_number = request.data.get('phone_number')

        if not phone_number:
            return Response({"error": "Phone number is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            recipient_profile = UserProfile.objects.get(phone_number=phone_number)
            recipient_user = recipient_profile.user
        except UserProfile.DoesNotExist:
            return Response({"error": "User with this phone number does not exist."}, status=status.HTTP_404_NOT_FOUND)

        current_user = request.user

        # Look for an existing chat room
        chat_room = ChatRoom.objects.filter(participants=current_user).filter(participants=recipient_user).first()

        room_existed = True
        if not chat_room:
            chat_room = ChatRoom.objects.create()
            chat_room.participants.add(current_user, recipient_user)
            room_existed = False

        return Response({
            "room_id": str(chat_room.id),
            "room_exists": room_existed,
            "participant": {
                "username": recipient_user.username,
                "phone_number": recipient_profile.phone_number,
                "profile_picture": recipient_profile.profile_picture.url if recipient_profile.profile_picture else None
            }
        }, status=status.HTTP_200_OK)
        
        

class AllMessagesView(APIView):
    def get(self, request):
        current_user = request.user
        phone_number = request.query_params.get('phone_number')

        if not phone_number:
            return Response({
                "status": status.HTTP_400_BAD_REQUEST,
                "data": None,
                "error": "شماره تماس ارسال نشده است."
            })

        try:
            other_profile = UserProfile.objects.get(phone_number=phone_number)
            other_user = other_profile.user
        except UserProfile.DoesNotExist:
            return Response({
                "status": status.HTTP_404_NOT_FOUND,
                "data": None,
                "error": "کاربر با این شماره پیدا نشد."
            })

        try:
            # پیدا کردن چت روم خصوصی بین دو کاربر
            room = ChatRoom.objects.filter(
                is_group_chat=False,
                participants=current_user
            ).filter(
                participants=other_user
            ).distinct().first()

            if not room:
                return Response({
                    "status": status.HTTP_200_OK,
                    "data": [],
                    "error": None
                })

            messages = Message.objects.filter(chat_room=room).select_related('sender').prefetch_related('attachments')

            message_list = []
            for msg in messages:
                message_list.append({
                    "id": msg.id,
                    "sender": msg.sender.username,
                    "sender_id": msg.sender.id,
                    "content": msg.content,
                    "timestamp": msg.timestamp.isoformat(),
                    "seen": msg.seen,
                    "attachments": [
                        {
                            "file": attachment.file.url,
                            "file_type": attachment.file_type
                        }
                        for attachment in msg.attachments.all()
                    ]
                })

            return Response({
                "status": status.HTTP_200_OK,
                "data": message_list,
                "error": None
            })

        except Exception as e:
            return Response({
                "status": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "data": None,
                "error": str(e)
            })