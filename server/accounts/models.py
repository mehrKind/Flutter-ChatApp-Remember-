from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
import os
from datetime import datetime
from django.conf import settings

def user_directory_path(instance, filename):
    # File will be uploaded to MEDIA_ROOT/user_<id>/<filename>
    now = datetime.now()
    timestamp = now.strftime("%Y%m%d_%H%M%S")
    ext = filename.split('.')[-1]
    new_filename = f"profile_{timestamp}.{ext}"
    return f'user_{instance.user.id}/{new_filename}'

def default_profile_picture():
    return os.path.join(settings.STATIC_URL, 'images/default.jpg')

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(max_length=500, blank=True)
    profile_picture = models.ImageField(
        upload_to=user_directory_path,
        default='default.jpg',
        blank=True,
        null=True
    )
    phone_number = models.CharField(max_length=20, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    online_status = models.BooleanField(default=False)
    last_online = models.DateTimeField(null=True, blank=True)
    
    # Privacy settings
    show_last_online = models.BooleanField(default=True)
    show_profile_picture = models.BooleanField(default=True)
    
    # Notification preferences
    message_notifications = models.BooleanField(default=True)
    sound_notifications = models.BooleanField(default=True)

    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.user.username}\'s Profile'


# # Signal to create/update user profile when user is created/updated
# @receiver(post_save, sender=User)
# def create_or_update_user_profile(sender, instance, created, **kwargs):
#     if created:
#         UserProfile.objects.create(user=instance)
#     instance.profile.save()