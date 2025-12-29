enum UserType { parent, nursery }

class User {
  final String id;
  final String name;
  final String email;
  final UserType type;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type == UserType.parent ? 'parent' : 'nursery',
      'phone': phone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      type: json['type'] == 'parent' ? UserType.parent : UserType.nursery,
      phone: json['phone'],
    );
  }
}
