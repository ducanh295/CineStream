import 'category.dart';
import 'movie.dart';

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

  const Favorite({
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
      movieId:
          (json['movieId'] as num?)
                  ?.toInt() ??
              0,
      title:
          json['title']?.toString() ??
              '',
      description:
          json['description']
              ?.toString(),
      posterUrl:
          json['posterUrl']?.toString(),
      trailerUrl:
          json['trailerUrl']?.toString(),
      duration:
          (json['duration'] as num?)
              ?.toInt(),
      releaseYear:
          (json['releaseYear'] as num?)
              ?.toInt(),
      categories:
          (json['categories']
                  as List<dynamic>?)
              ?.map(
                (item) => item.toString(),
              )
              .toList() ??
              const [],
      addedAt:
          json['addedAt'] != null
              ? DateTime.tryParse(
                  json['addedAt'].toString(),
                )
              : null,
    );
  }

  Movie toMovie() {
    return Movie(
      id: movieId,
      title: title,
      description: description,
      posterUrl: posterUrl,
      trailerUrl: trailerUrl,
      duration: duration,
      releaseYear: releaseYear,
      type: 0,
      videoStatus: 0,
      categories: categories
          .map(
            (name) => Category(
              id: 0,
              name: name,
            ),
          )
          .toList(),
    );
  }
}