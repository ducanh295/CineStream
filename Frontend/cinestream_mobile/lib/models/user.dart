import 'profile.dart';

class User {
  final int id;
  final String username;
  final String email;
  final int role;
  final Profile? profile;

  // Email
  final bool isEmailConfirmed;

  // Account lock
  final bool isLocked;
  final String? lockReason;

  // Premium
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.profile,
    this.isEmailConfirmed = false,
    this.isLocked = false,
    this.lockReason,
    this.isPremium = false,
    this.premiumExpiresAt,
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

      profile:
          json['profile'] is Map
              ? Profile.fromJson(
                  Map<String, dynamic>.from(
                    json['profile'] as Map,
                  ),
                )
              : null,

      isEmailConfirmed:
          json['isEmailConfirmed'] == true,

      isLocked:
          json['isLocked'] == true,

      lockReason:
          json['lockReason']?.toString(),

      isPremium:
          json['isPremium'] == true,

      premiumExpiresAt:
          json['premiumExpiresAt'] != null
              ? DateTime.tryParse(
                  json['premiumExpiresAt']
                      .toString(),
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'profile': profile?.toJson(),
      'isEmailConfirmed': isEmailConfirmed,
      'isLocked': isLocked,
      'lockReason': lockReason,
      'isPremium': isPremium,
      'premiumExpiresAt':
          premiumExpiresAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role == 1;

  /// Kiểm tra Premium có còn hiệu lực hay không.
  bool get premiumActive {
    if (!isPremium) {
      return false;
    }

    // Backend có thể đánh dấu Premium nhưng chưa có ngày hết hạn.
    // Trong trường hợp đó xem như Premium vẫn đang hoạt động.
    if (premiumExpiresAt == null) {
      return true;
    }

    return premiumExpiresAt!
        .isAfter(DateTime.now());
  }
}

