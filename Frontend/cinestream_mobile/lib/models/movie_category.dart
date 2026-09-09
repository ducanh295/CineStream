class MovieCategory {
  final int movieId;
  final int categoryId;

  MovieCategory({
    required this.movieId,
    required this.categoryId,
  });

  factory MovieCategory.fromJson(Map<String, dynamic> json) {
    return MovieCategory(
      movieId: json['movieId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'categoryId': categoryId,
    };
  }
}