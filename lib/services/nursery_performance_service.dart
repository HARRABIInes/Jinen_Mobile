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
        
        print('📊 FULL API Response: ${jsonEncode(data)}');
        
        if (data['success'] == true || data['reviews'] != null) {
          final List<dynamic> reviews = data['reviews'] ?? [];
          
          print('📊 Reviews from API: ${jsonEncode(reviews)}');
          
          // Normalize review data
          final normalizedReviews = reviews.map((review) {
            final normalized = {
              'id': review['id'],
              'rating': review['rating'],
              'comment': review['comment'],
              'createdAt': review['created_at'] ?? review['createdAt'],
              'parentName': review['parent_name'] ?? review['parentName'],
              'parentId': review['parent_id'] ?? review['parentId'],
            };
            print('📊 Normalized review: ${jsonEncode(normalized)}');
            return normalized;
          }).toList();
          
          // Calculate average rating
          double averageRating = 0.0;
          if (normalizedReviews.isNotEmpty) {
            final totalRating = normalizedReviews.fold<double>(
              0.0,
              (sum, review) {
                final rating = review['rating'];
                final ratingValue = rating is double
                    ? rating
                    : (rating is int ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0.0);
                return sum + ratingValue;
              },
            );
            averageRating = totalRating / normalizedReviews.length;
          }

          // Group reviews by rating
          final ratingDistribution = <int, int>{};
          for (int i = 1; i <= 5; i++) {
            ratingDistribution[i] = 0;
          }
          
          for (var review in normalizedReviews) {
            final rating = review['rating'];
            // Parse rating as double first, then convert to int
            final ratingDouble = rating is double
                ? rating
                : (rating is int 
                    ? (rating).toDouble()
                    : double.tryParse(rating.toString()) ?? 0.0);
            final ratingValue = ratingDouble.toInt();
            
            print('📊 Distribution - Rating: $rating -> Double: $ratingDouble -> Int: $ratingValue');
            
            if (ratingValue >= 1 && ratingValue <= 5) {
              ratingDistribution[ratingValue] = (ratingDistribution[ratingValue] ?? 0) + 1;
            }
          }

          return {
            'success': true,
            'nurseryId': nurseryId,
            'totalReviews': normalizedReviews.length,
            'averageRating': double.parse(averageRating.toStringAsFixed(2)),
            'reviews': normalizedReviews,
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
