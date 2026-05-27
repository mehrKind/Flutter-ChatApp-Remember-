import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:remember/services/routes.dart';
import '../../Components/CustomDrawer.dart';
import '../../services/config.dart';
import '../../services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatLists extends StatefulWidget {
  const ChatLists({super.key});

  @override
  State<ChatLists> createState() => _ChatListsState();
}


class ChatPreview {
  final String roomId;
  final String lastMessage;
  final String senderName;
  final String? profilePicture;
  final DateTime timestamp;
  final String? rawPhoneNumber;
  final String normalizedPhoneNumber; // This will store the standardized format

  ChatPreview({
    required this.roomId,
    required this.lastMessage,
    required this.senderName,
    required this.timestamp,
    this.profilePicture,
    this.rawPhoneNumber,
  }) : normalizedPhoneNumber = _normalizePhoneNumber(rawPhoneNumber ?? '');

  static String _normalizePhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.startsWith('98')) {
      digits = digits.substring(2);
      if (digits.length == 10) return '0$digits';
    }
    else if (digits.startsWith('9') && digits.length == 10) return '0$digits';
    else if (digits.startsWith('09') && digits.length == 11) return digits;

    return digits; // Return as-is if doesn't match expected patterns
  }

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['last_message'];
    final otherUser = json['other_participant'];

    return ChatPreview(
      roomId: json['chat_room_id'].toString(),
      lastMessage: lastMessage != null ? lastMessage['content'] ?? '' : '',
      senderName: otherUser != null ? otherUser['username'] ?? '' : 'Unknown',
      profilePicture: otherUser != null ? otherUser['profile_picture'] : null,
      timestamp: lastMessage != null
          ? DateTime.parse(lastMessage['timestamp'])
          : DateTime.parse(json['created_at']),
      rawPhoneNumber: otherUser != null ? otherUser['phone_number'] : null,
    );
  }
}


class _ChatListsState extends State<ChatLists> {
  String selectedTab = 'Personal';

  Widget buildTab(String label) {
    final isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  late WebSocketChannel _chatListChannel;
  List<ChatPreview> _chatList = [];

  @override
  void initState() {
    super.initState();
    fetchInitialChatList();
    initWebSocket();
  }
  Future<void> fetchInitialChatList() async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = Uri.parse('$serverUrl:$serverPort/api/v1/chat/all_chats');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.body);
        final List<dynamic> data = res['data'];

        setState(() {
          _chatList = data.map((json) => ChatPreview.fromJson(json)).toList();
        });
      } else {
        debugPrint('Failed to load chat list: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception fetching chat list: $e');
    }
  }


  void initWebSocket() async {
    final userId = await StorageService.getUserId();
    final uri = Uri.parse('$socketUrl:$serverPort/ws/chat-list/$userId/');
    _chatListChannel = WebSocketChannel.connect(uri);


    _chatListChannel.stream.listen((event) {
      final data = jsonDecode(event);
      updateChatList(ChatPreview.fromJson(data));
    });
  }

  void updateChatList(ChatPreview preview) {
    final index = _chatList.indexWhere((c) => c.roomId == preview.roomId);
    setState(() {
      if (index >= 0) {
        _chatList[index] = preview;
        _chatList.insert(0, _chatList.removeAt(index)); // move to top
      } else {
        _chatList.insert(0, preview);
      }
    });
  }

  @override
  void dispose() {
    _chatListChannel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            title: const Text(
              "Remember",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 23.0,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Image.asset(
                  'assets/images/icons/menu.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Image.asset(
                  'assets/images/icons/Search.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chatPage);
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/ChatList_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildTab('Personal'),
                    const SizedBox(width: 10),
                    buildTab('Groups'),
                    const SizedBox(width: 10),
                    buildTab('Calls'),
                  ],
                ),

                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatList.length,
                    itemBuilder: (context, index) {
                      final chat = _chatList[index];
                      return GestureDetector(
                        onTap: () {
                          if (chat.normalizedPhoneNumber.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatPage,
                              arguments: {
                                'contactName': chat.senderName,
                                'contactPhone': chat.normalizedPhoneNumber,
                                'roomId': chat.roomId,
                                'isGroupChat': false,
                                'profilePicture': chat.profilePicture,
                              },
                            );
                          } else {
                            // Handle case where phone number couldn't be normalized
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid phone number format')),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2F3A).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: chat.profilePicture != null
                                    ? Image.network(chat.profilePicture!, width: 56, height: 56, fit: BoxFit.cover)
                                    : Image.asset('assets/images/profile.jpg', width: 56, height: 56, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.senderName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chat.lastMessage,
                                      style: const TextStyle(
                                        color: Color(0xFF9099AE),
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    TimeOfDay.fromDateTime(chat.timestamp).format(context),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.done_all, size: 16, color: Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()  {
          Navigator.pushNamed(context, AppRoutes.contactsPage);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFCA9FFE), Color(0xFF8259FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/icons/Edit.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),

    );
  }
}
