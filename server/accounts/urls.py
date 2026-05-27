from django.urls import path
from . import views


urlpatterns = [
    path("register", views.UserRegistrationAPIView.as_view(), name="user_registration"),
]

