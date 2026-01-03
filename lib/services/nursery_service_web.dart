import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nursery.dart';

/// Web-compatible nursery service using HTTP API
class NurseryServiceWeb {
  static const String baseUrl = 'http://localhost:3000/api';

  // Create new nursery
  Future<Nursery?> createNursery({
    required String ownerId,
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required int totalSpots,
    String? description,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? hours,
    String? ageRange,
    String? imageUrl,
    List<String>? facilities,
    List<String>? activities,
  }) async {
    try {
      final requestBody = {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': email,
        'hours': hours,
        'price_per_month': pricePerMonth,
        'total_spots': totalSpots,
        'age_range': ageRange,
        'photo_url': imageUrl,
        'facilities': facilities ?? [],
        'activities': activities ?? [],
      };

      print('Creating nursery with data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/nurseries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final nurseryData = data['nursery'];
          return Nursery(
            id: nurseryData['id'],
            ownerId: nurseryData['ownerId'],
            name: nurseryData['name'],
            description: nurseryData['description'] ?? '',
            address: nurseryData['address'],
            city: nurseryData['city'],
            postalCode: nurseryData['postalCode'] ?? '',
            phone: nurseryData['phone'] ?? '',
            email: nurseryData['email'] ?? '',
            hours: nurseryData['hours'] ?? '',
            price: _parseDouble(nurseryData['price']),
            totalSpots: _parseInt(nurseryData['totalSpots']),
            availableSpots: _parseInt(nurseryData['availableSpots']),
            ageRange: nurseryData['ageRange'] ?? '',
            rating: _parseDouble(nurseryData['rating']),
            photo: nurseryData['photoUrl'] ?? '',
            facilities: List<String>.from(nurseryData['facilities'] ?? []),
            activities: List<String>.from(nurseryData['activities'] ?? []),
            distance: 0.0,
            reviewCount: 0,
            staff: 0,
          );
        }
      } else {
        print('Failed to create nursery. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error creating nursery: $e');
      return null;
    }
  }

  // Helper methods to safely parse numeric values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Search nurseries with filters
  Future<List<Nursery>> searchNurseries({
    String? city,
    double? maxPrice,
    double? minRating,
    int? minAvailableSpots,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (city != null) queryParams['city'] = city;
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (minAvailableSpots != null) {
        queryParams['min_spots'] = minAvailableSpots.toString();
      }

      final uri =
          Uri.parse('$baseUrl/nurseries').replace(queryParameters: queryParams);
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> nurseriesData = data['nurseries'];
          final nurseries = nurseriesData.map((nurseryData) {
            final photoUrl = nurseryData['photoUrl'] ?? '';
            print('📸 Nursery ${nurseryData['name']}: photoUrl = $photoUrl');
            return Nursery(
              id: nurseryData['id'],
              ownerId: nurseryData['ownerId'],
              name: nurseryData['name'],
              description: nurseryData['description'] ?? '',
              address: nurseryData['address'],
              city: nurseryData['city'],
              postalCode: nurseryData['postalCode'] ?? '',
              phone: nurseryData['phone'] ?? '',
              email: nurseryData['email'] ?? '',
              hours: nurseryData['hours'] ?? '',
              price: _parseDouble(nurseryData['price']),
              totalSpots: _parseInt(nurseryData['totalSpots']),
              availableSpots: _parseInt(nurseryData['availableSpots']),
              ageRange: nurseryData['ageRange'] ?? '',
              rating: _parseDouble(nurseryData['rating']),
              photo: photoUrl,
              facilities: List<String>.from(nurseryData['facilities'] ?? []),
              activities: List<String>.from(nurseryData['activities'] ?? []),
              distance: 0.0,
              reviewCount: _parseInt(nurseryData['reviewCount']),
              staff: 0,
            );
          }).toList();
          return nurseries;
        }
      }
      return [];
    } catch (e) {
      print('Error searching nurseries: $e');
      return [];
    }
  }

  // Get nursery by ID
  Future<Nursery?> getNurseryById(String nurseryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/$nurseryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final nurseryData = data['nursery'];
          return Nursery(
            id: nurseryData['id'],
            ownerId: nurseryData['ownerId'],
            name: nurseryData['name'],
            description: nurseryData['description'] ?? '',
            address: nurseryData['address'],
            city: nurseryData['city'],
            postalCode: nurseryData['postalCode'] ?? '',
            phone: nurseryData['phone'] ?? '',
            email: nurseryData['email'] ?? '',
            hours: nurseryData['hours'] ?? '',
            price: _parseDouble(nurseryData['price']),
            availableSpots: _parseInt(nurseryData['availableSpots']),
            totalSpots: _parseInt(nurseryData['totalSpots']),
            ageRange: nurseryData['ageRange'] ?? '',
            rating: _parseDouble(nurseryData['rating']),
            photo: nurseryData['photoUrl'] ?? '',
            facilities: List<String>.from(nurseryData['facilities'] ?? []),
            activities: List<String>.from(nurseryData['activities'] ?? []),
            distance: 0.0,
            reviewCount: 0,
            staff: 0,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error creating nursery: $e');
      return null;
    }
  }

  // Get nurseries by owner
  Future<List<Nursery>> getNurseriesByOwner(String ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nurseries/owner/$ownerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> nurseriesData = data['nurseries'];
          return nurseriesData.map((nurseryData) {
            return Nursery(
              id: nurseryData['id'],
              ownerId: nurseryData['ownerId'],
              name: nurseryData['name'],
              description: nurseryData['description'] ?? '',
              address: nurseryData['address'],
              city: nurseryData['city'],
              postalCode: nurseryData['postalCode'] ?? '',
              phone: nurseryData['phone'] ?? '',
              email: nurseryData['email'] ?? '',
              hours: nurseryData['hours'] ?? '',
              price: _parseDouble(nurseryData['price']),
              totalSpots: _parseInt(nurseryData['totalSpots']),
              availableSpots: _parseInt(nurseryData['availableSpots']),
              ageRange: nurseryData['ageRange'] ?? '',
              rating: _parseDouble(nurseryData['rating']),
              photo: nurseryData['photoUrl'] ?? '',
              facilities: List<String>.from(nurseryData['facilities'] ?? []),
              activities: List<String>.from(nurseryData['activities'] ?? []),
              distance: 0.0,
              reviewCount: _parseInt(nurseryData['reviewCount']),
              staff: _parseInt(nurseryData['staff']),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting nurseries by owner: $e');
      return [];
    }
  }
}
