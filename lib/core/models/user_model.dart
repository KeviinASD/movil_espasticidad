class UserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String roleTier;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.roleTier,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      roleTier: json['roleTier'] as String? ?? 'User',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'roleTier': roleTier,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, email: $email, fullName: $fullName)';
}
