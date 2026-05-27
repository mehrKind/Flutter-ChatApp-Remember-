import 'package:flutter/material.dart';

// ================================ Server Setting =============================
const serverUrl = "http://45.129.39.155";
const socketUrl = "ws://45.129.39.155";
const serverPort = 8000;
// ================================ Colors Setting =============================
const Map<String, Color> mainColors = {
  "mainPink": Color(0xFFCB68FF),
  "mainPurpple": Color(0xFF7431FF),
  "mainBg": Color(0xFF121925),
  // Add more colors as needed
};
Color getColorByName(String colorName) {
  return mainColors[colorName] ?? Colors.transparent;
}
// ================================ API Setting ================================
const api = {
// account (login & register)
  "register": '$serverUrl:$serverPort/api/v1/accounts/register',

  // CHAT
  "all_chats": '$serverUrl:$serverPort/api/v1/chat/all_chats',
  "start_or_get_room": '$serverUrl:$serverPort/api/v1/chat/start-or-get-room',
  "chat_history": "$serverUrl:$serverPort/api/v1/chat/chat_history",

}