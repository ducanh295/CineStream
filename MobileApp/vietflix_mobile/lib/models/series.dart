import 'season.dart';
class Series {
  final int id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? trailerUrl;
  final int? releaseYear;
  final double averageRating;
  final int viewCount;
  final List<Season> seasons;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Series({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.trailerUrl,
    this.releaseYear,
    this.averageRating = 0,
    this.viewCount = 0,
    this.seasons = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      posterUrl: json['posterUrl'],
      trailerUrl: json['trailerUrl'],
      releaseYear: json['releaseYear'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      viewCount: json['viewCount'] ?? 0,
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map(
                (item) => Season.fromJson(
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
      'trailerUrl': trailerUrl,
      'releaseYear': releaseYear,
      'averageRating': averageRating,
      'viewCount': viewCount,
      'seasons': seasons.map((item) => item.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}