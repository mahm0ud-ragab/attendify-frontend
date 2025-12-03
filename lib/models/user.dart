// This file defines what a User looks like in our app

class User {
  final int id;
  final String email;
  final String name;
  final String role; // 'student' or 'lecturer'

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  // Convert JSON from API to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}