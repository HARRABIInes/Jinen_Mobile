import 'dart:convert';
import 'package:http/http.dart' as http;

class ParentNurseriesServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get all nurseries where a parent has enrolled children
  static Future<Map<String, dynamic>> getParentNurseries(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parents/$parentId/nurseries'),
      );

      print('📋 Parent nurseries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'parentId': data['parentId'],
            'nurseries': List<Map<String, dynamic>>.from(
              (data['nurseries'] ?? []).map((nursery) => {
                'id': nursery['id'],
                'name': nursery['name'],
                'description': nursery['description'],
                'phone': nursery['phone'],
                'email': nursery['email'],
                'address': nursery['address'],
                'city': nursery['city'],
                'rating': nursery['rating'],
                'availableSpots': nursery['availableSpots'],
                'totalSpots': nursery['totalSpots'],
                'childCount': nursery['childCount'],
              })
            )
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to fetch nurseries'
      };
    } catch (e) {
      print('❌ Error fetching parent nurseries: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}
