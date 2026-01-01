import 'dart:convert';
import 'package:http/http.dart' as http;

class NurseryDashboardService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get nursery statistics
  Future<Map<String, dynamic>?> getNurseryStats(String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/$nurseryId/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['stats'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching nursery stats: $e');
      return null;
    }
  }

  // Get daily schedule
  Future<List<Map<String, dynamic>>> getDailySchedule(String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/$nurseryId/schedule'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['schedule']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching schedule: $e');
      return [];
    }
  }

  // Create schedule item
  Future<Map<String, dynamic>?> createScheduleItem({
    required String nurseryId,
    required String timeSlot,
    required String activityName,
    String? description,
    int? participantCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nurseries/$nurseryId/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timeSlot': timeSlot,
          'activityName': activityName,
          'description': description,
          'participantCount': participantCount ?? 0,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['schedule'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating schedule: $e');
      return null;
    }
  }

  // Update schedule item
  Future<Map<String, dynamic>?> updateScheduleItem({
    required String scheduleId,
    String? timeSlot,
    String? activityName,
    String? description,
    int? participantCount,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/schedule/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timeSlot': timeSlot,
          'activityName': activityName,
          'description': description,
          'participantCount': participantCount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['schedule'];
        }
      }
      return null;
    } catch (e) {
      print('Error updating schedule: $e');
      return null;
    }
  }

  // Delete schedule item
  Future<bool> deleteScheduleItem(String scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedule/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  // Accept enrollment
  Future<bool> acceptEnrollment(String enrollmentId) async {
    try {
      print('📤 Sending accept request for enrollment: $enrollmentId');
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments/$enrollmentId/accept'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error accepting enrollment: $e');
      return false;
    }
  }

  // Reject enrollment
  Future<bool> rejectEnrollment(String enrollmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments/$enrollmentId/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error rejecting enrollment: $e');
      return false;
    }
  }
}
