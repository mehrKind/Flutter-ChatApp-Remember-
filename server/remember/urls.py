from django.contrib import admin
from django.urls import path, include
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.conf import settings
from django.conf.urls.static import static

api_v1 = "v1"
api_v2 = "v2"

urlpatterns = [
    path('admin/', admin.site.urls),
    path(f'api/{api_v1}/accounts/', include('accounts.urls')),
    path(f'api/{api_v1}/chat/', include('chat.urls'))
]

# Serve static & media files during development
urlpatterns += staticfiles_urlpatterns()
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
