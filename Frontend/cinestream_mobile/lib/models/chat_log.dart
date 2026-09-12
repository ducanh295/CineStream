class ChatLog {
  final int id;
  final int userId;
  final String message;
  final bool isFromAI;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatLog({
    required this.id,
    required this.userId,
    required this.message,
    this.isFromAI = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return ChatLog(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      message: json['message'] ?? '',
      isFromAI: json['isFromAI'] ?? false,
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
      'userId': userId,
      'message': message,
      'isFromAI': isFromAI,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}