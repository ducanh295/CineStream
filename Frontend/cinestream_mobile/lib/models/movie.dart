import 'category.dart';

class Movie {
  final int id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? trailerUrl;
  final int? duration;
  final int? releaseYear;
  final int type;
  final int videoStatus;
  final bool isFeatured;
  final int publishStatus; // 0 = Draft (Ẩn), 1 = ComingSoon (Sắp chiếu), 2 = Published (Đã phát hành)
  final List<Category> categories;

  // Có ở MovieDetailDto
  final String? videoUrl;
  final String streamType;

  // Có ở MovieDetailDto
  final DateTime? createdAt;

  const Movie({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.trailerUrl,
    this.duration,
    this.releaseYear,
    this.type = 0,
    this.videoStatus = 0,
    this.isFeatured = false,
    this.publishStatus = 2,
    this.categories = const [],
    this.videoUrl,
    this.streamType = 'NONE',
    this.createdAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      posterUrl: json['posterUrl']?.toString(),
      trailerUrl: json['trailerUrl']?.toString(),
      duration: (json['duration'] as num?)?.toInt(),
      releaseYear: (json['releaseYear'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt() ?? 0,
      videoStatus: (json['videoStatus'] as num?)?.toInt() ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      publishStatus: (json['publishStatus'] as num?)?.toInt() ?? 2,
      categories: (json['categories'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) => Category.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          const [],
      videoUrl: json['videoUrl']?.toString(),
      streamType: json['streamType']?.toString() ?? 'NONE',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isSeries => type == 1;

  bool get isDraft => publishStatus == 0;
  bool get isComingSoon => publishStatus == 1;
  bool get isPublished => publishStatus == 2;

  bool get hasVideo =>
      videoStatus == 1 &&
      videoUrl != null &&
      videoUrl!.isNotEmpty;
}
