import 'package:remember/Screens/Chat/UserChat.dart';
import 'package:remember/Screens/Contacts/ContactsPage.dart';

import './routes.dart';
import 'package:flutter/material.dart';
import 'package:remember/accounts/SplashScreen.dart';
import 'package:remember/accounts/SignupPage.dart';
import 'package:remember/Screens/Chat/ChatLists.dart';

class AppRouter{
  static Route<dynamic> generateRout(RouteSettings settings){
    switch (settings.name){
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_)=> const SplashScreen());
      case AppRoutes.signUpPage:
        return MaterialPageRoute(builder: (_)=> const SignupPage());
      case AppRoutes.chatList:
        return MaterialPageRoute(builder: (_)=> const ChatLists());
      case AppRoutes.callsPage:
        return MaterialPageRoute(builder: (_)=> const SplashScreen());
      case AppRoutes.chatPage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_)=> UserChat(
            contactName: args['contactName'],
            contactPhone: args['contactPhone'],
          ),
        );
      case AppRoutes.contactsPage:
        return MaterialPageRoute(builder: (_)=> const ContactsPage());
      default:
        return MaterialPageRoute(builder:
            (_)=> Scaffold(
          body: Center(
            child: Text("No route defined here for ${settings.name}"),
          ),
        ));
    }
  }
}