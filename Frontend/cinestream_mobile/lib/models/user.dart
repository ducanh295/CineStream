class User {
  final int id;
  final String username;
  final String email;
  final int role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _parseInt(json['role']),
      createdAt: _parseDateTime(
        json['createdAt'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'createdAt':
          createdAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  User copyWith({
    int? id,
    String? username,
    String? email,
    int? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt:
          createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // ROLE
  // ============================================================

  bool get isAdmin => role == 1;

  bool get isUser => role == 0;

  String get roleName {
    switch (role) {
      case 1:
        return 'Quản trị viên';
      case 0:
        return 'Người dùng';
      default:
        return 'Không xác định';
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'User('
        'id: $id, '
        'username: $username, '
        'email: $email, '
        'role: $role, '
        'createdAt: $createdAt'
        ')';
  }
}