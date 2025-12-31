import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/support/support_chatbot.dart';

class ChatStorage {
  static const String _storageKey = 'chat_messages';

  // Save messages to SharedPreferences
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert messages to a list of maps
    final List<Map<String, dynamic>> messagesJson = messages
        .map((message) => {
              'text': message.text,
              'isUser': message.isUser,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            })
        .toList();
    
    // Save as JSON string
    await prefs.setString(_storageKey, jsonEncode(messagesJson));
  }

  // Load messages from SharedPreferences
  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesString = prefs.getString(_storageKey);
      
      if (messagesString == null || messagesString.isEmpty) {
        return [];
      }
      
      final List<dynamic> messagesJson = jsonDecode(messagesString);
      
      return messagesJson
          .map((json) => ChatMessage(
                text: json['text'] as String,
                isUser: json['isUser'] as bool,
              ))
          .toList();
    } catch (e) {
      print('Error loading chat messages: $e');
      return [];
    }
  }

  // Clear all saved messages
  static Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
