class Profile {
final String? displayName;
final String? avatarUrl;
final String? bio;

const Profile({
this.displayName,
this.avatarUrl,
this.bio,
});

factory Profile.fromJson(Map<String, dynamic> json) {
return Profile(
displayName: json['displayName']?.toString(),
avatarUrl: json['avatarUrl']?.toString(),
bio: json['bio']?.toString(),
);
}

Map<String, dynamic> toJson() {
return {
'displayName': displayName,
'avatarUrl': avatarUrl,
'bio': bio,
};
}
}
