import 'dart:convert';
import 'package:http/http.dart' as http;

class NurseryPerformanceService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get all reviews and ratings for a nursery
  static Future<Map<String, dynamic>> getNurseryReviews(String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/$nurseryId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📊 Performance Response status: ${response.statusCode}');
      print('📊 Performance Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true || data['reviews'] != null) {
          final List<dynamic> reviews = data['reviews'] ?? [];
          
          // Calculate average rating
          double averageRating = 0.0;
          if (reviews.isNotEmpty) {
            final totalRating = reviews.fold<double>(
              0.0,
              (sum, review) {
                final rating = review['rating'];
                final ratingValue = rating is double
                    ? rating
                    : (rating is int ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0.0);
                return sum + ratingValue;
              },
            );
            averageRating = totalRating / reviews.length;
          }

          // Group reviews by rating
          final ratingDistribution = <int, int>{};
          for (int i = 1; i <= 5; i++) {
            ratingDistribution[i] = 0;
          }
          
          for (var review in reviews) {
            final rating = review['rating'];
            final ratingValue = rating is double
                ? rating.toInt()
                : (rating is int ? rating : int.tryParse(rating.toString()) ?? 0);
            if (ratingValue >= 1 && ratingValue <= 5) {
              ratingDistribution[ratingValue] = (ratingDistribution[ratingValue] ?? 0) + 1;
            }
          }

          return {
            'success': true,
            'nurseryId': nurseryId,
            'totalReviews': reviews.length,
            'averageRating': double.parse(averageRating.toStringAsFixed(2)),
            'reviews': reviews,
            'ratingDistribution': ratingDistribution,
          };
        }
        
        return {
          'success': false,
          'error': 'Invalid response format',
          'totalReviews': 0,
          'averageRating': 0.0,
          'reviews': [],
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch reviews',
        'totalReviews': 0,
        'averageRating': 0.0,
        'reviews': [],
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    } catch (e) {
      print('❌ Error fetching nursery reviews: $e');
      return {
        'success': false,
        'error': e.toString(),
        'totalReviews': 0,
        'averageRating': 0.0,
        'reviews': [],
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }
}
