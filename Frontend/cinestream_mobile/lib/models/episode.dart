class Episode {
  final int id;
  final int seasonId;
  final int episodeNumber;
  final String? title;
  final String? videoUrl;
  final int videoStatus;
  final int? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Episode({
    required this.id,
    required this.seasonId,
    required this.episodeNumber,
    this.title,
    this.videoUrl,
    this.videoStatus = 0,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      seasonId: json['seasonId'] ?? 0,
      episodeNumber: json['episodeNumber'] ?? 0,
      title: json['title'],
      videoUrl: json['videoUrl'],
      videoStatus: json['videoStatus'] ?? 0,
      duration: json['duration'],
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
      'seasonId': seasonId,
      'episodeNumber': episodeNumber,
      'title': title,
      'videoUrl': videoUrl,
      'videoStatus': videoStatus,
      'duration': duration,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get hasVideo => videoStatus == 1 && videoUrl != null;
}