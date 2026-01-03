import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversationServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get or create a conversation between parent and nursery
  static Future<Map<String, dynamic>?> getOrCreateConversation({
    required String parentId,
    required String nurseryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/get-or-create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parentId': parentId,
          'nurseryId': nurseryId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['conversation'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      return null;
    }
  }

  /// Get all conversations for a user
  static Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// Get all messages in a conversation
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['messages'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message in a conversation
  static Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    String? recipientId,
    required String content,
  }) async {
    try {
      print('📤 Sending message to: $baseUrl/conversations/$conversationId/messages');
      print('📤 Body: {senderId: $senderId, content: $content}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'content': content,
        }),
      );

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['message'];
        }
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ Error sending message: $e');
      return null;
    }
  }

  /// Mark messages as read in a conversation
  static Future<bool> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      return false;
    }
  }
}
