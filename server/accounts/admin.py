from django.contrib import admin
from .models import UserProfile

class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'bio', 'phone_number', 'birth_date', 'online_status', 'last_online', 'created_at', 'updated_at')
    search_fields = ('user__username', 'bio', 'phone_number')
    list_filter = ('online_status', 'show_last_online', 'show_profile_picture', 'message_notifications', 'sound_notifications')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'last_online')

    def get_queryset(self, request):
        # Override to include related user information
        qs = super().get_queryset(request)
        return qs.select_related('user')

admin.site.register(UserProfile, UserProfileAdmin)
