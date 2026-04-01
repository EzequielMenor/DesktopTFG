class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String role;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    required this.role,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      role: json['role'] as String,
      createdAt: json['createdAt'] as String?,
    );
  }
}
