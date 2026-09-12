import 'profile.dart';

class User {
final int id;
final String username;
final String email;
final int role;
final Profile? profile;

const User({
required this.id,
required this.username,
required this.email,
required this.role,
this.profile,
});

factory User.fromJson(Map<String, dynamic> json) {
return User(
id: (json['id'] as num?)?.toInt() ?? 0,
username: json['username']?.toString() ?? '',
email: json['email']?.toString() ?? '',
role: (json['role'] as num?)?.toInt() ?? 0,
profile: json['profile'] is Map<String, dynamic>
? Profile.fromJson(
Map<String, dynamic>.from(json['profile'] as Map),
)
: null,
);
}

bool get isAdmin => role == 1;
}
