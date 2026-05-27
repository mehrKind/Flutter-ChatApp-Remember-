import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remember/services/config.dart';
import 'package:remember/services/storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http; // => For API calls
import 'dart:convert';
import 'package:flutter/services.dart'; // => For Clipboard
import 'dart:ui'; // =>  For blur


class UserChat extends StatefulWidget {
  final String contactName;
  final String contactPhone;

  const UserChat._({
    super.key,
    required this.contactName,
    required this.contactPhone,
  });

  factory UserChat({
    Key? key,
    required String contactName,
    required String contactPhone,
  }) {
    return UserChat._(
      key: key,
      contactName: contactName,
      contactPhone: _normalizePhoneNumber(contactPhone),
    );
  }

  static String _normalizePhoneNumber(String phone) {
    // Same normalization logic as above
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.startsWith('98')) {
      digits = digits.substring(2);
      if (digits.length == 10) return '0$digits';
    }
    else if (digits.startsWith('9') && digits.length == 10) return '0$digits';
    else if (digits.startsWith('09') && digits.length == 11) return digits;

    return digits;
  }

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  String? _roomId;
  Map<String, dynamic>? _selectedMessage;
  Offset? _tapPosition;
  bool _showMessageActions = false;



  Future<void> _loadChatHistory() async {
    try {
      final token = await StorageService.getAccessToken();
      final userId = await StorageService.getUserId();

      if (token == null || userId == null) {
        throw Exception('Access token or user ID not found in storage');
      }

      final response = await http.get(
        Uri.parse('${api['chat_history']}/?phone_number=${widget.contactPhone}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> messages = responseBody['data'] ?? [];

        setState(() {
          _messages.clear();
          _messages.addAll(messages.map((message) {
            return {
              'text': message['content']?.toString() ?? '',
              'isMe': message['sender_id'].toString() == userId,
              'timestamp': message['timestamp']?.toString() ?? DateTime.now().toString(),
            };
          }).toList());
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        throw Exception(
            'API Error ${response.statusCode}: ${responseBody['error'] ?? response.body}'
        );
      }
    } catch (e, stackTrace) {
      print('Error loading chat history: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chat history: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadChatHistory();
  }


  Future<void> _initializeChat() async {
    try {
      setState(() => _isConnecting = true);

      final token = await StorageService.getAccessToken();
      if (token == null) {
        throw Exception('No access token found in storage');
      }

      final response = await http.post(
        Uri.parse(api['start_or_get_room']!),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone_number': widget.contactPhone,
        }),
      );

      final responseBody = json.decode(response.body);

      print('API Response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        _roomId = responseBody['room_id'].toString();
        _connectToWebSocket();
      } else {
        throw Exception(
            'API Error ${response.statusCode}: ${responseBody['error'] ?? response.body}'
        );
      }
    } catch (e, stackTrace) {
      print('Error in _initializeChat: $e\n$stackTrace'); // Full error logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  bool get _isTyping => _controller.text.trim().isNotEmpty;
  TextDirection _inputDirection = TextDirection.ltr;
  String _inputFontFamily = 'poppins';

  Future<void> _connectToWebSocket() async {
    try {
      final myPhone = await StorageService.getUserPhone();
      final wsUrl = '${socketUrl}:$serverPort/ws/chat/$_roomId/$myPhone/';



      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((message) async {
        final data = json.decode(message);

        final messageData = data['message'];
        if (messageData == null) return;

        final sender = messageData['sender'];
        final senderPhone = sender != null ? sender['phone_number'] : null;

        final myPhone = await StorageService.getUserPhone();

        final msgContent = messageData['content'];

        // Only add the message if it's NOT from me
        final isMe = senderPhone != null && myPhone != null && senderPhone == myPhone;

        setState(() {
          _messages.add({
            'text': msgContent,
            'isMe': isMe,
            'timestamp': messageData['timestamp'] ?? DateTime.now().toString(),
          });
        });
        _scrollToBottom();

      });

    } catch (e) {
      print('[WS CONNECTION ERROR] $e');
      _reconnectWebSocket();
    }
  }



  Future<void> _reconnectWebSocket() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _connectToWebSocket();
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _channel == null) return;

    final message = _controller.text.trim();
    _controller.clear();

    // Add message locally
    // setState(() {
    //   _messages.add({
    //     'text': message, // Ensure this is a String
    //     'isMe': true,
    //     'timestamp': DateTime.now().toString(),
    //   });
    // });
    _scrollToBottom();


    try {
      // Format message according to your Django consumer expectations
      final myPhone = await StorageService.getUserPhone();
      final messageData = {
        'message': message,
        'receiver': widget.contactPhone,
      };
      _channel!.sink.add(json.encode(messageData));

    } catch (e) {
      print('[SEND ERROR] $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: ${e.toString()}')),
      );
    }
  }



  Widget _buildPopupAction(String label, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMessageActions = false; // hide popup when tapped
        });
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 20, height: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _channel?.sink.close();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }


  bool isRTL(String text) {
    final rtlRegExp = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+');
    return rtlRegExp.hasMatch(text.trim());
  }

  void _onInputChanged(String text) {
    final isRtl = isRTL(text);
    setState(() {
      _inputDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;
      _inputFontFamily = isRtl ? 'sans' : 'poppins';
    });
  }

  //  Copy message
  void _copyToClipboard() {
    if (_selectedMessage != null) {
      final messageText = _selectedMessage!['text'].toString();
      Clipboard.setData(ClipboardData(text: messageText));
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Copied to clipboard')),
      // );
    }
  }

  // reply action
  void _replyToMessage() {
    // TODO: Implement reply logic
    print('Reply tapped');
  }

  void _editMessage() {
    // TODO: Implement edit logic
    print('Edit tapped');
  }



  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;


    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Main UI Layer
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 34),
                // 🔹 Top Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'assets/images/icons/arrow-left.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.contactName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset('assets/images/icons/video.png', width: 24, height: 24),
                        const SizedBox(width: 14),
                        Image.asset('assets/images/icons/phone.png', width: 24, height: 24),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final messageText = message['text'] is String
                          ? message['text']
                          : message['text'].toString();

                      return GestureDetector(
                        onTapDown: (details) {
                          setState(() {
                            _tapPosition = details.globalPosition;
                            _selectedMessage = message;
                            _showMessageActions = true;
                          });
                        },
                        child: Align(
                          alignment: message['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message['isMe']
                                  ? Colors.white.withOpacity(0.24)
                                  : const Color(0xFF2A2F3A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: message['isMe']
                                    ? const Color(0xFF8B8B8B)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              messageText,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: isRTL(messageText) ? 'sans' : 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🔹 Input Area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Input field with emoji and mic/send
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2534),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF595B5E)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Image.asset(
                                'assets/images/icons/emoji.png',
                                width: 22,
                                height: 22,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onChanged: _onInputChanged,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: _inputFontFamily,
                                ),
                                textDirection: _inputDirection,
                                textAlign: _inputDirection == TextDirection.rtl
                                    ? TextAlign.right
                                    : TextAlign.left,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: 'Type here...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 35,
                                height: 35,
                                margin: const EdgeInsets.only(left: 10),
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
                                    _isTyping
                                        ? 'assets/images/icons/send.png'
                                        : 'assets/images/icons/Voice.png',
                                    width: 20,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // File & Image Icons
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                      child: !_isTyping
                          ? Row(
                        key: const ValueKey('icons'),
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Image.asset(
                              'assets/images/icons/Image.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: Image.asset(
                              'assets/images/icons/Folder.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      )
                          : const SizedBox(
                        key: ValueKey('empty'),
                        width: 0,
                        height: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Blur Overlay and Popup
          if (_showMessageActions && _tapPosition != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showMessageActions = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),

          if (_showMessageActions && _tapPosition != null)
            Positioned(
              top: _tapPosition!.dy - 60,
              left: _tapPosition!.dx - 100,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPopupAction('Copy', 'assets/images/icons/copy_2.png', _copyToClipboard),
                      const SizedBox(width: 15),
                      _buildPopupAction('Reply', 'assets/images/icons/reply.png', _replyToMessage),
                      const SizedBox(width: 15),
                      _buildPopupAction('Edit', 'assets/images/icons/Edit_2.png', _editMessage),
                      const SizedBox(width: 15),
                      _buildPopupAction('Delete', 'assets/images/icons/trash.png', _editMessage),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}