class Favorite {
  final int userId;
  final int movieId;
  final DateTime? createdAt;

  Favorite({
    required this.userId,
    required this.movieId,
    this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['userId'] ?? 0,
      movieId: json['movieId'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'movieId': movieId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}