import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> getNurseryReviews(
      String nurseryId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/nurseries/$nurseryId/reviews'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': List<Map<String, dynamic>>.from(data['reviews'] ?? [])
        };
      }
      return {'success': false, 'error': 'Failed to load reviews'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> postReview({
    required String nurseryId,
    required String parentId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nurseryId': nurseryId,
          'parentId': parentId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'review': data['review']};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to post review'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> editReview({
    required String reviewId,
    required String parentId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parentId': parentId,
          'rating': rating,
          'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'review': data['review']};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to edit review'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteReview({
    required String reviewId,
    required String parentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'parentId': parentId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to delete review'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

/// Service to manage reviews and ratings for nurseries
class ReviewService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Create or update a review for a nursery
  static Future<Map<String, dynamic>> submitReview({
    required String nurseryId,
    required String parentId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nurseryId': nurseryId,
          'parentId': parentId,
          'rating': rating,
          'comment': comment,
        }),
      );

      print('⭐ Response status: ${response.statusCode}');
      print('⭐ Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'review': data['review'],
            'nurseryRating': data['nurseryRating'],
          };
        }
      }

      return {'success': false, 'error': 'Failed to submit review'};
    } catch (e) {
      print('❌ Error submitting review: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all reviews for a nursery
  static Future<Map<String, dynamic>> getNurseryReviews(
      String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/$nurseryId/reviews'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'nurseryId': data['nurseryId'],
            'totalReviews': data['totalReviews'] ?? 0,
            'reviews': List<Map<String, dynamic>>.from(
                (data['reviews'] ?? []).map((review) => {
                      'id': review['id'],
                      'rating': review['rating'],
                      'comment': review['comment'],
                      'createdAt': review['createdAt'],
                      'parentName': review['parentName'],
                      'parentId': review['parentId'],
                    }))
          };
        }
      }

      return {'success': false, 'error': 'Failed to fetch reviews'};
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get a specific review by parent for a nursery
  static Future<Map<String, dynamic>?> getParentReview(
    String parentId,
    String nurseryId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/parent/$parentId/nursery/$nurseryId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['review'] != null) {
          return {
            'id': data['review']['id'],
            'rating': data['review']['rating'],
            'comment': data['review']['comment'],
            'createdAt': data['review']['createdAt'],
            'updatedAt': data['review']['updatedAt'],
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error fetching parent review: $e');
      return null;
    }
  }

  /// Delete a review
  static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'nurseryRating': data['nurseryRating'],
          };
        }
      }

      return {'success': false, 'error': 'Failed to delete review'};
    } catch (e) {
      print('❌ Error deleting review: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
