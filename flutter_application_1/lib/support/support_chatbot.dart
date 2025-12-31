import 'package:flutter/material.dart';
import 'dart:math'; // For the sin function
import 'package:flutter_application_1/support/gemini_service.dart';
import 'package:flutter_application_1/support/chat_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For base64 decoding

class SupportChatbotScreen extends StatefulWidget {
  const SupportChatbotScreen({Key? key}) : super(key: key);

  @override
  State<SupportChatbotScreen> createState() => _SupportChatbotScreenState();
}

class _SupportChatbotScreenState extends State<SupportChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final GeminiService _geminiService = GeminiService();
  String? _userProfileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _loadUserProfileImage();
  }

  Future<void> _loadChatHistory() async {
    final savedMessages = await ChatStorage.loadMessages();

    if (savedMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(savedMessages);
      });
      _scrollToBottom();
    } else {
      // Add initial welcome message if no saved messages
      _addBotMessage(
        "Hello! I'm your Morocco 2030 World Cup assistant. How can I help you today?",
      );
    }
  }

  Future<void> _loadUserProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userData.exists &&
            userData.data()!.containsKey('profileImageBase64')) {
          setState(() {
            _userProfileImageBase64 = userData.data()!['profileImageBase64'];
          });
        }
      }
    } catch (e) {
      print('Error loading user profile image: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _saveChatMessages();
    _scrollToBottom();
  }

  void _saveChatMessages() {
    ChatStorage.saveMessages(_messages);
  }

  void _handleSubmitted(String text) {
    _messageController.clear();

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _saveChatMessages();
    _scrollToBottom();

    // Simulate AI thinking time
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isTyping = false;
      });
      _generateResponse(text);
    });
  }

  Future<void> _generateResponse(String userMessage) async {
    try {
      // Create a context-aware prompt
      String prompt =
          "You are a helpful assistant for the Morocco 2030 World Cup. " +
          "Answer the following question about the event: $userMessage";

      // Get response from Gemini
      String response = await _geminiService.generateResponse(prompt);

      _addBotMessage(response);
    } catch (e) {
      _addBotMessage("Sorry, I encountered an error: ${e.toString()}");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'World Cup Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(100, 0, 0, 0),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/banner2030.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info dialog about the chatbot
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('About This Assistant'),
                      content: const Text(
                        'This chatbot provides information about the Morocco 2030 World Cup including venues, tickets, transportation, and more.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(
                              0xFF065d67,
                            ), // Text color
                            backgroundColor:
                                Colors.transparent, // Button background
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Optional effect when pressed
                            overlayColor: const Color(
                              0xFF065d67,
                            ).withOpacity(0.1),
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Light pattern background
          color: Colors.grey[50],
          image: DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/subtle-white-feathers.png',
            ),
            repeat: ImageRepeat.repeat,
            opacity: 0.5,
          ),
        ),
        child: Column(
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Chat messages
            Expanded(
              child:
                  _messages.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showAvatar =
                              index == 0 ||
                              (index > 0 &&
                                  _messages[index - 1].isUser !=
                                      message.isUser);

                          return _buildEnhancedMessage(message, showAvatar);
                        },
                      ),
            ),

            // Typing indicator bubble
            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bot avatar for typing indicator
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFDCB00),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // Typing bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18.0),
                          topRight: Radius.circular(18.0),
                          bottomLeft: Radius.circular(4.0),
                          bottomRight: Radius.circular(18.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildTypingDot(),
                          const SizedBox(width: 4),
                          _buildTypingDot(delay: 300),
                          const SizedBox(width: 4),
                          _buildTypingDot(delay: 600),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4.0,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      // Text input field
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: _handleSubmitted,
                          decoration: InputDecoration(
                            hintText: "Type your question...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 12.0,
                            ),
                            isDense: true,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                        ),
                      ),

                      // Send button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065d67),
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF065d67).withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                          onPressed:
                              () => _handleSubmitted(_messageController.text),
                          tooltip: 'Send Message',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the typing animation dots
  Widget _buildTypingDot({int delay = 0}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(
              0xFF065d67,
            ).withOpacity(0.4 + (0.6 * (sin(value * 6.28)))),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // Updated _buildEnhancedMessage to use user profile image
  Widget _buildEnhancedMessage(ChatMessage message, bool showAvatar) {
    final bool isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          if (!isUser && showAvatar)
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFDCB00),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 22,
              ),
            )
          else if (!isUser && !showAvatar)
            const SizedBox(width: 36),

          const SizedBox(width: 8.0),

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF065d67) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18.0),
                  topRight: const Radius.circular(18.0),
                  bottomLeft: Radius.circular(isUser ? 18.0 : 4.0),
                  bottomRight: Radius.circular(isUser ? 4.0 : 18.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color:
                            isUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // User avatar with profile image
          if (isUser && showAvatar)
            _userProfileImageBase64 != null
                ? CircleAvatar(
                  radius: 18,
                  backgroundImage: MemoryImage(
                    base64Decode(_userProfileImageBase64!),
                  ),
                )
                : CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue[300],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                )
          else if (isUser && !showAvatar)
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFFDCB00),
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF065d67) : Colors.grey[200],
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Text(
                text,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}
