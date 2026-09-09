class Rating {
  final int id;
  final int userId;
  final int movieId;
  final int score;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rating({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.score,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      movieId: json['movieId'] ?? 0,
      score: json['score'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'movieId': movieId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}