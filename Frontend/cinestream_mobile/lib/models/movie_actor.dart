class MovieActor {
  final int movieId;
  final int actorId;

  MovieActor({
    required this.movieId,
    required this.actorId,
  });

  factory MovieActor.fromJson(Map<String, dynamic> json) {
    return MovieActor(
      movieId: json['movieId'] ?? 0,
      actorId: json['actorId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'actorId': actorId,
    };
  }
}