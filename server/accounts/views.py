from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from .models import UserProfile
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from rest_framework.permissions import AllowAny

class UserRegistrationAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        context = {
            "status": status.HTTP_200_OK,
            "data": None,
            "error": None
        }

        username = request.data.get('username')
        phone_number = request.data.get('phone_number')
        password = request.data.get('password')

        # Validate required fields
        if not username or not phone_number or not password:
            context["status"] = status.HTTP_400_BAD_REQUEST
            context["error"] = "Username, phone number, and password are required"
            return Response(context, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Check if username exists in User model
            user_exists = User.objects.filter(username=username).exists()
            # Check if phone number exists in UserProfile
            phone_exists = UserProfile.objects.filter(phone_number=phone_number).exists()

            # Case 1: Both username and phone number exist
            if user_exists and phone_exists:
                # Verify they belong to the same user
                try:
                    profile = UserProfile.objects.get(phone_number=phone_number)
                    if profile.user.username != username:
                        context["status"] = status.HTTP_400_BAD_REQUEST
                        context["error"] = "Username and phone number don't match"
                        return Response(context, status=status.HTTP_400_BAD_REQUEST)
                    
                    # Authenticate user
                    user = authenticate(username=username, password=password)
                    if user:
                        refresh = RefreshToken.for_user(user)
                        context["data"] = {
                            "message": "User logged in successfully",
                            "user_id": user.id,
                            "username": user.username,
                            "phone_number": phone_number,   # Added phone number here
                            "tokens": {
                                "access": str(refresh.access_token),
                                "refresh": str(refresh)
                            }
                        }
                        print(f"[INFO] User {username} logged in successfully with phone number {phone_number}")
                        return Response(context, status=status.HTTP_200_OK)
                    else:
                        context["status"] = status.HTTP_400_BAD_REQUEST
                        context["error"] = "Invalid password"
                        return Response(context, status=status.HTTP_400_BAD_REQUEST)
                
                except UserProfile.DoesNotExist:
                    context["status"] = status.HTTP_400_BAD_REQUEST
                    context["error"] = "User profile not found"
                    return Response(context, status=status.HTTP_400_BAD_REQUEST)

            # Case 2: Username exists but phone number doesn't - ERROR
            elif user_exists and not phone_exists:
                context["status"] = status.HTTP_400_BAD_REQUEST
                context["error"] = "Username exists but phone number doesn't match our records"
                return Response(context, status=status.HTTP_400_BAD_REQUEST)

            # Case 3: Phone number exists but username doesn't - ERROR
            elif not user_exists and phone_exists:
                context["status"] = status.HTTP_400_BAD_REQUEST
                context["error"] = "Phone number exists but username doesn't match our records"
                return Response(context, status=status.HTTP_400_BAD_REQUEST)

            # Case 4: Neither exists - create new user
            else:
                user = User.objects.create_user(
                    username=username,
                    password=password
                )
                
                UserProfile.objects.create(
                    user=user,
                    phone_number=phone_number
                )
                
                # Authenticate and generate tokens
                user = authenticate(username=username, password=password)
                refresh = RefreshToken.for_user(user)
                
                context["data"] = {
                    "message": "User registered and logged in successfully",
                    "user_id": user.id,
                    "username": user.username,
                    "phone_number": phone_number,   # Added phone number here
                    "tokens": {
                        "access": str(refresh.access_token),
                        "refresh": str(refresh)
                    }
                }
                return Response(context, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            context["status"] = status.HTTP_500_INTERNAL_SERVER_ERROR
            context["error"] = str(e)
            return Response(context, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
