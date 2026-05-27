from django.contrib import admin
from .models import ChatRoom, Message, Attachment

class AttachmentInline(admin.TabularInline):
    model = Attachment
    extra = 1  # Number of empty forms to display

class MessageInline(admin.TabularInline):
    model = Message
    extra = 1  # Number of empty forms to display

class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ('name', 'is_group_chat', 'created_at', 'updated_at', 'id')
    search_fields = ('name',)
    list_filter = ('is_group_chat',)
    inlines = [MessageInline]  # Show messages inline in the chat room admin

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.prefetch_related('participants')  # Optimize query for participants

class MessageAdmin(admin.ModelAdmin):
    list_display = ('chat_room', 'sender', 'content', 'timestamp', 'seen', 'is_deleted')
    search_fields = ('content', 'sender__username')
    list_filter = ('seen', 'is_deleted', 'chat_room')
    ordering = ('-timestamp',)
    inlines = [AttachmentInline]  # Show attachments inline in the message admin

class AttachmentAdmin(admin.ModelAdmin):
    list_display = ('message', 'file', 'file_type', 'uploaded_at')
    search_fields = ('file_type',)
    list_filter = ('file_type',)
    ordering = ('-uploaded_at',)

# Register the models with their respective admin classes
admin.site.register(ChatRoom, ChatRoomAdmin)
admin.site.register(Message, MessageAdmin)
admin.site.register(Attachment, AttachmentAdmin)
