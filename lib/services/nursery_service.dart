import 'database_service.dart';
import '../models/nursery.dart';

class NurseryService {
  final DatabaseService _db = DatabaseService.instance;

  // Create new nursery
  Future<Nursery?> createNursery({
    required String ownerId,
    required String name,
    required String address,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? description,
    String? hours,
    String? phone,
    String? email,
    String? photoUrl,
    double? pricePerMonth,
    required int totalSpots,
    int? staffCount,
    String? ageRange,
    List<String>? facilities,
    List<String>? activities,
  }) async {
    try {
      return await _db.transaction((conn) async {
        // Insert nursery
        final result = await conn.mappedResultsQuery(
          '''
          INSERT INTO nurseries 
          (owner_id, name, address, city, postal_code, latitude, longitude, 
           description, hours, phone, email, photo_url, price_per_month, 
           available_spots, total_spots, staff_count, age_range)
          VALUES (@ownerId, @name, @address, @city, @postalCode, @latitude, @longitude,
                  @description, @hours, @phone, @email, @photoUrl, @pricePerMonth,
                  @totalSpots, @totalSpots, @staffCount, @ageRange)
          RETURNING *
          ''',
          substitutionValues: {
            'ownerId': ownerId,
            'name': name,
            'address': address,
            'city': city,
            'postalCode': postalCode,
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
            'hours': hours,
            'phone': phone,
            'email': email,
            'photoUrl': photoUrl,
            'pricePerMonth': pricePerMonth,
            'totalSpots': totalSpots,
            'staffCount': staffCount,
            'ageRange': ageRange,
          },
        );

        if (result.isEmpty) return null;

        final nurseryId = result.first['nurseries']!['id'] as String;

        // Insert facilities
        if (facilities != null && facilities.isNotEmpty) {
          for (final facility in facilities) {
            await conn.execute(
              'INSERT INTO nursery_facilities (nursery_id, facility_name) VALUES (@nurseryId, @facility)',
              substitutionValues: {
                'nurseryId': nurseryId,
                'facility': facility
              },
            );
          }
        }

        // Insert activities
        if (activities != null && activities.isNotEmpty) {
          for (final activity in activities) {
            await conn.execute(
              'INSERT INTO nursery_activities (nursery_id, activity_name) VALUES (@nurseryId, @activity)',
              substitutionValues: {
                'nurseryId': nurseryId,
                'activity': activity
              },
            );
          }
        }

        return await getNurseryById(nurseryId);
      });
    } catch (e) {
      print('Error creating nursery: $e');
      return null;
    }
  }

  // Get nursery by ID with all details
  Future<Nursery?> getNurseryById(String nurseryId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM nurseries WHERE id = @nurseryId',
        substitutionValues: {'nurseryId': nurseryId},
      );

      if (result.isEmpty) return null;

      final row = result.first['nurseries']!;

      // Get facilities
      final facilitiesResult = await _db.query(
        'SELECT facility_name FROM nursery_facilities WHERE nursery_id = @nurseryId',
        substitutionValues: {'nurseryId': nurseryId},
      );
      final facilities = facilitiesResult
          .map((r) => r['nursery_facilities']!['facility_name'] as String)
          .toList();

      // Get activities
      final activitiesResult = await _db.query(
        'SELECT activity_name FROM nursery_activities WHERE nursery_id = @nurseryId',
        substitutionValues: {'nurseryId': nurseryId},
      );
      final activities = activitiesResult
          .map((r) => r['nursery_activities']!['activity_name'] as String)
          .toList();

      return Nursery(
        id: row['id'] as String,
        name: row['name'] as String,
        address: row['address'] as String,
        city: row['city'] as String?,
        postalCode: row['postal_code'] as String?,
        distance: 0.0, // Calculate if needed
        rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: row['review_count'] as int? ?? 0,
        price: (row['price_per_month'] as num?)?.toDouble() ?? 0.0,
        availableSpots: row['available_spots'] as int? ?? 0,
        totalSpots: row['total_spots'] as int,
        hours: row['hours'] as String? ?? '',
        photo: row['photo_url'] as String? ?? '',
        description: row['description'] as String? ?? '',
        activities: activities,
        facilities: facilities.isEmpty ? null : facilities,
        staff: row['staff_count'] as int? ?? 0,
        ageRange: row['age_range'] as String? ?? '',
        phone: row['phone'] as String?,
        email: row['email'] as String?,
        ownerId: row['owner_id'] as String?,
      );
    } catch (e) {
      print('Error getting nursery: $e');
      return null;
    }
  }

  // Search nurseries with filters
  Future<List<Nursery>> searchNurseries({
    String? city,
    double? maxPrice,
    int? minAvailableSpots,
    double? minRating,
  }) async {
    try {
      String whereClause = 'WHERE 1=1';
      Map<String, dynamic> values = {};

      if (city != null) {
        whereClause += ' AND city ILIKE @city';
        values['city'] = '%$city%';
      }
      if (maxPrice != null) {
        whereClause += ' AND price_per_month <= @maxPrice';
        values['maxPrice'] = maxPrice;
      }
      if (minAvailableSpots != null) {
        whereClause += ' AND available_spots >= @minSpots';
        values['minSpots'] = minAvailableSpots;
      }
      if (minRating != null) {
        whereClause += ' AND rating >= @minRating';
        values['minRating'] = minRating;
      }

      final result = await _db.query(
        'SELECT * FROM nurseries $whereClause ORDER BY rating DESC',
        substitutionValues: values,
      );

      List<Nursery> nurseries = [];
      for (var row in result) {
        final nursery = await getNurseryById(row['nurseries']!['id'] as String);
        if (nursery != null) nurseries.add(nursery);
      }

      return nurseries;
    } catch (e) {
      print('Error searching nurseries: $e');
      return [];
    }
  }

  // Get nurseries by owner
  Future<List<Nursery>> getNurseriesByOwner(String ownerId) async {
    try {
      final result = await _db.query(
        'SELECT id FROM nurseries WHERE owner_id = @ownerId',
        substitutionValues: {'ownerId': ownerId},
      );

      List<Nursery> nurseries = [];
      for (var row in result) {
        final nursery = await getNurseryById(row['nurseries']!['id'] as String);
        if (nursery != null) nurseries.add(nursery);
      }

      return nurseries;
    } catch (e) {
      print('Error getting nurseries by owner: $e');
      return [];
    }
  }

  // Update nursery
  Future<bool> updateNursery({
    required String nurseryId,
    String? name,
    String? address,
    String? city,
    String? description,
    String? hours,
    String? phone,
    double? pricePerMonth,
    int? availableSpots,
  }) async {
    try {
      await _db.execute(
        '''
        UPDATE nurseries
        SET name = COALESCE(@name, name),
            address = COALESCE(@address, address),
            city = COALESCE(@city, city),
            description = COALESCE(@description, description),
            hours = COALESCE(@hours, hours),
            phone = COALESCE(@phone, phone),
            price_per_month = COALESCE(@pricePerMonth, price_per_month),
            available_spots = COALESCE(@availableSpots, available_spots),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @nurseryId
        ''',
        substitutionValues: {
          'nurseryId': nurseryId,
          'name': name,
          'address': address,
          'city': city,
          'description': description,
          'hours': hours,
          'phone': phone,
          'pricePerMonth': pricePerMonth,
          'availableSpots': availableSpots,
        },
      );
      return true;
    } catch (e) {
      print('Error updating nursery: $e');
      return false;
    }
  }

  // Delete nursery
  Future<bool> deleteNursery(String nurseryId) async {
    try {
      await _db.execute(
        'DELETE FROM nurseries WHERE id = @nurseryId',
        substitutionValues: {'nurseryId': nurseryId},
      );
      return true;
    } catch (e) {
      print('Error deleting nursery: $e');
      return false;
    }
  }
}
