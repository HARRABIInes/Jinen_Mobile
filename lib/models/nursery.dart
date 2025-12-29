import 'review.dart';

class Nursery {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? postalCode;
  final double distance;
  final double rating;
  final int reviewCount;
  final double price;
  final int availableSpots;
  final int totalSpots;
  final String hours;
  final String photo;
  final String description;
  final List<String> activities;
  final List<String>? facilities;
  final int staff;
  final String ageRange;
  final String? phone;
  final String? email;
  final String? ownerId;
  final List<Review>? reviews;

  Nursery({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.postalCode,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.availableSpots,
    required this.totalSpots,
    required this.hours,
    required this.photo,
    required this.description,
    required this.activities,
    this.facilities,
    required this.staff,
    required this.ageRange,
    this.phone,
    this.email,
    this.ownerId,
    this.reviews,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'price': price,
      'availableSpots': availableSpots,
      'totalSpots': totalSpots,
      'hours': hours,
      'photo': photo,
      'description': description,
      'activities': activities,
      'facilities': facilities,
      'staff': staff,
      'ageRange': ageRange,
      'phone': phone,
      'email': email,
      'ownerId': ownerId,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
    };
  }

  factory Nursery.fromJson(Map<String, dynamic> json) {
    return Nursery(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postalCode'],
      distance: json['distance'].toDouble(),
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      price: json['price'].toDouble(),
      availableSpots: json['availableSpots'],
      totalSpots: json['totalSpots'],
      hours: json['hours'],
      photo: json['photo'],
      description: json['description'],
      activities: List<String>.from(json['activities']),
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : null,
      staff: json['staff'],
      ageRange: json['ageRange'],
      phone: json['phone'],
      email: json['email'],
      ownerId: json['ownerId'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((r) => Review.fromJson(r)).toList()
          : null,
    );
  }
}
