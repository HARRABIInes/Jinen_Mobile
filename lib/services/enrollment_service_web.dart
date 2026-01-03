import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EnrollmentServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  // Convert date from MM/dd/yyyy to yyyy-MM-dd for PostgreSQL
  String _convertDateFormat(String dateStr) {
    try {
      // Try parsing MM/dd/yyyy format
      final date = DateFormat('MM/dd/yyyy').parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      // If already in correct format or other format, return as-is
      return dateStr;
    }
  }

  // Create enrollment
  Future<Map<String, dynamic>?> createEnrollment({
    required String childName,
    required String birthDate,
    required String parentName,
    required String parentPhone,
    required String nurseryId,
    required String startDate,
    String? notes,
    String? parentId,
  }) async {
    try {
      // Convert dates to PostgreSQL format (yyyy-MM-dd)
      final formattedBirthDate = _convertDateFormat(birthDate);
      final formattedStartDate = _convertDateFormat(startDate);
      
      print('📅 Converting dates: birthDate=$birthDate -> $formattedBirthDate, startDate=$startDate -> $formattedStartDate');
      
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'childName': childName,
          'birthDate': formattedBirthDate,
          'parentName': parentName,
          'parentPhone': parentPhone,
          'nurseryId': nurseryId,
          'startDate': formattedStartDate,
          'notes': notes,
          'parentId': parentId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['enrollment'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating enrollment: $e');
      return null;
    }
  }

  // Get enrollments by nursery
  Future<List<Map<String, dynamic>>> getEnrollmentsByNursery(
      String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enrollments/nursery/$nurseryId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['enrollments']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching enrollments: $e');
      return [];
    }
  }

  // Get all enrollments
  Future<List<Map<String, dynamic>>> getAllEnrollments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enrollments'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['enrollments']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all enrollments: $e');
      return [];
    }
  }

  // Get enrollments by parent ID
  Future<List<Map<String, dynamic>>> getEnrollmentsByParent(
      String parentId) async {
    try {
      print('📋 Fetching enrollments for parent: $parentId');
      final response = await http.get(
        Uri.parse('$baseUrl/enrollments/parent/$parentId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Found ${data['count']} enrollments for parent');
          return List<Map<String, dynamic>>.from(data['enrollments']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching parent enrollments: $e');
      return [];
    }
  }

  // Update enrollment status (accept/reject)
  Future<bool> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/enrollments/$enrollmentId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating enrollment status: $e');
      return false;
    }
  }
}
