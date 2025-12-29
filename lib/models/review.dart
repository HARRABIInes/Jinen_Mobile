class Review {
  final String id;
  final String parentName;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.id,
    required this.parentName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentName': parentName,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      parentName: json['parentName'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      date: json['date'],
    );
  }
}
