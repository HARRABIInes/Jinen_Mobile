import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child.dart';

/// Web-compatible child service using HTTP API
class ChildServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  // Create new child
  Future<Child?> createChild({
    required String parentId,
    required String name,
    required int age,
    DateTime? dateOfBirth,
    String? photoUrl,
    String? medicalNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/children'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parent_id': parentId,
          'name': name,
          'age': age,
          'date_of_birth': dateOfBirth?.toIso8601String(),
          'photo_url': photoUrl,
          'medical_notes': medicalNotes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final childData = data['child'];
          return Child(
            id: childData['id'],
            name: childData['name'],
            age: childData['age'],
            photo: childData['photo_url'],
            nurseryId: null,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error creating child: $e');
      return null;
    }
  }

  // Get child by ID
  Future<Child?> getChildById(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final childData = data['child'];
          return Child(
            id: childData['id'],
            name: childData['name'],
            age: childData['age'],
            photo: childData['photo_url'],
            nurseryId: childData['nursery_id'],
          );
        }
      }
      return null;
    } catch (e) {
      print('Error getting child: $e');
      return null;
    }
  }

  // Get all children by parent ID
  Future<List<Child>> getChildrenByParentId(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parents/$parentId/children'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final children = data['children'] as List;
          return children
              .map((child) => Child(
                    id: child['id'],
                    name: child['name'],
                    age: child['age'],
                    photo: child['photo_url'],
                    nurseryId: child['nursery_id'],
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting children: $e');
      return [];
    }
  }

  // Update child
  Future<bool> updateChild({
    required String childId,
    String? name,
    int? age,
    DateTime? dateOfBirth,
    String? photoUrl,
    String? medicalNotes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/children/$childId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'age': age,
          'date_of_birth': dateOfBirth?.toIso8601String(),
          'photo_url': photoUrl,
          'medical_notes': medicalNotes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating child: $e');
      return false;
    }
  }

  // Delete child
  Future<bool> deleteChild(String childId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/children/$childId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting child: $e');
      return false;
    }
  }

  // Get children's activities
  Future<List<Map<String, dynamic>>> getChildActivities(
      String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId/activities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['activities'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting child activities: $e');
      return [];
    }
  }

  // Get children's homework
  Future<List<Map<String, dynamic>>> getChildHomework(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId/homework'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['homework'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting child homework: $e');
      return [];
    }
  }
}
