class Actor {
  final int id;
  final String name;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Actor({
    required this.id,
    required this.name,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Actor.fromJson(
    Map<String, dynamic> json,
  ) {
    return Actor(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(
                json['id']?.toString() ?? '0',
              ) ??
              0,
      name: json['name']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(
              json['updatedAt'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt':
          createdAt?.toIso8601String(),
      'updatedAt':
          updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Actor('
        'id: $id, '
        'name: $name, '
        'photoUrl: $photoUrl, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}