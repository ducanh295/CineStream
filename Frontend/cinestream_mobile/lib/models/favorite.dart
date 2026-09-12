
class Favorite {
  final int movieId;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? trailerUrl;
  final int? duration;
  final int? releaseYear;
  final List<String> categories;
  final DateTime? addedAt;

  Favorite({
    required this.movieId,
    required this.title,
    this.description,
    this.posterUrl,
    this.trailerUrl,
    this.duration,
    this.releaseYear,
    this.categories = const [],
    this.addedAt,
  });

  factory Favorite.fromJson(
    Map<String, dynamic> json,
  ) {
    return Favorite(
      movieId: _parseInt(json['movieId']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      posterUrl: json['posterUrl']?.toString(),
      trailerUrl: json['trailerUrl']?.toString(),
      duration: _parseNullableInt(
        json['duration'],
      ),
      releaseYear: _parseNullableInt(
        json['releaseYear'],
      ),
      categories: _parseCategories(
        json['categories'],
      ),
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(
              json['addedAt'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'trailerUrl': trailerUrl,
      'duration': duration,
      'releaseYear': releaseYear,
      'categories': categories,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  static int? _parseNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static List<String> _parseCategories(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (item) => item.toString(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  @override
  String toString() {
    return 'Favorite('
        'movieId: $movieId, '
        'title: $title, '
        'posterUrl: $posterUrl, '
        'releaseYear: $releaseYear, '
        'categories: $categories, '
        'addedAt: $addedAt'
        ')';
  }
}