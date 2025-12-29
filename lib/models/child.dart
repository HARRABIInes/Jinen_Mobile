class Child {
  final String id;
  final String name;
  final int age;
  final String? photo;
  final String? nurseryId;

  Child({
    required this.id,
    required this.name,
    required this.age,
    this.photo,
    this.nurseryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'photo': photo,
      'nurseryId': nurseryId,
    };
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      photo: json['photo'],
      nurseryId: json['nurseryId'],
    );
  }
}
