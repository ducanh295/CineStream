import 'episode.dart';
class Season {
  final int id;
  final int seriesId;
  final int seasonNumber;
  final String? title;
  final List<Episode> episodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Season({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    this.title,
    this.episodes = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      seriesId: json['seriesId'] ?? 0,
      seasonNumber: json['seasonNumber'] ?? 0,
      title: json['title'],
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map(
                (item) => Episode.fromJson(
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
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
      'title': title,
      'episodes': episodes.map((item) => item.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}