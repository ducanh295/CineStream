import 'actor.dart';
import 'category.dart';

class Movie {
  final int id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? videoUrl;
  final int videoStatus;
  final String? trailerUrl;
  final int? duration;
  final int? releaseYear;
  final int type;
  final double averageRating;
  final int viewCount;
  final List<Category> categories;
  final List<Actor> actors;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Movie({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.videoUrl,
    this.videoStatus = 0,
    this.trailerUrl,
    this.duration,
    this.releaseYear,
    this.type = 0,
    this.averageRating = 0,
    this.viewCount = 0,
    this.categories = const [],
    this.actors = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      posterUrl: json['posterUrl'],
      videoUrl: json['videoUrl'],
      videoStatus: json['videoStatus'] ?? 0,
      trailerUrl: json['trailerUrl'],
      duration: json['duration'],
      releaseYear: json['releaseYear'],
      type: json['type'] ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      viewCount: json['viewCount'] ?? 0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map(
                (item) => Category.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      actors: (json['actors'] as List<dynamic>?)
              ?.map(
                (item) => Actor.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
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
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'videoStatus': videoStatus,
      'trailerUrl': trailerUrl,
      'duration': duration,
      'releaseYear': releaseYear,
      'type': type,
      'averageRating': averageRating,
      'viewCount': viewCount,
      'categories': categories.map((item) => item.toJson()).toList(),
      'actors': actors.map((item) => item.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isSeries => type == 1;

  bool get hasVideo => videoStatus == 1 && videoUrl != null;
}