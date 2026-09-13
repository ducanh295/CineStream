import 'profile.dart';

class User {
  final int id;
  final String username;
  final String email;
  final int role;

  // Trạng thái tài khoản Premium
  final bool isPremium;

  // Thời điểm Premium hết hạn
  final DateTime? premiumExpiresAt;

  final Profile? profile;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.profile,
  });

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,

      username:
          json['username']?.toString() ?? '',

      email:
          json['email']?.toString() ?? '',

      role:
          (json['role'] as num?)?.toInt() ?? 0,

      isPremium:
          json['isPremium'] == true,

      premiumExpiresAt:
          json['premiumExpiresAt'] != null
              ? DateTime.tryParse(
                  json['premiumExpiresAt']
                      .toString(),
                )
              : null,

      profile:
          json['profile']
                  is Map<String, dynamic>
              ? Profile.fromJson(
                  Map<String, dynamic>.from(
                    json['profile'] as Map,
                  ),
                )
              : null,
    );
  }

  bool get isAdmin => role == 1;

  bool get premiumActive {
    if (!isPremium) {
      return false;
    }

    if (premiumExpiresAt == null) {
      return true;
    }

    return premiumExpiresAt!
        .isAfter(DateTime.now());
  }
}