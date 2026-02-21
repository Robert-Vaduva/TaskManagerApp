class User {
  final int? id;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] ?? "",
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
    );
  }
}