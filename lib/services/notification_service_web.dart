import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get all notifications for a user
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      print('🔔 Fetching notifications for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          print('📬 Found ${notifications.length} notifications');
          return notifications;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      print('✅ Marking notification as read: $notificationId');
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead(String userId) async {
    try {
      print('✅ Marking all notifications as read for user: $userId');
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$userId/read-all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      print('🗑️ Deleting notification: $notificationId');
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String userId) async {
    try {
      print('📊 Fetching unread count for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$userId/unread-count'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final count = data['unreadCount'] ?? 0;
          print('📊 Unread notifications: $count');
          return count;
        }
      }
      return 0;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      return 0;
    }
  }
}
