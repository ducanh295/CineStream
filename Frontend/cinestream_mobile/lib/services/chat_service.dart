import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/chat_log.dart';
import '../models/movie.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final Dio _dio = ApiClient.instance.dio;

  /// Gửi tin nhắn tới CineBot.
  ///
  /// POST /api/ai/chat
  ///
  /// Body:
  /// {
  ///   "message": "..."
  /// }
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "message": "...",
  ///   "data": {
  ///     "reply": "...",
  ///     "recommendedMovies": [...],
  ///     "createdAt": "..."
  ///   }
  /// }
  Future<ChatResponse> sendMessage(String message) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      throw Exception('Nội dung tin nhắn không được để trống.');
    }

    try {
      final response = await _dio.post(
        ApiConstants.aiChat,
        data: <String, dynamic>{
          'message': trimmedMessage,
        },
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Dữ liệu phản hồi từ CineBot không hợp lệ.',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'CineBot không thể trả lời lúc này.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception(
          'Dữ liệu CineBot trả về không hợp lệ.',
        );
      }

      return ChatResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể kết nối tới CineBot.',
        ),
      );
    }
  }

  /// Lấy lịch sử trò chuyện của người dùng hiện tại.
  ///
  /// GET /api/ai/history?limit=30
  Future<List<ChatLog>> getHistory({
    int limit = 30,
  }) async {
    final safeLimit = limit.clamp(1, 100);

    try {
      final response = await _dio.get(
        ApiConstants.aiHistory,
        queryParameters: <String, dynamic>{
          'limit': safeLimit,
        },
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Dữ liệu lịch sử trò chuyện không hợp lệ.',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể tải lịch sử trò chuyện.',
        );
      }

      final data = body['data'];

      if (data is! List) {
        return const <ChatLog>[];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => ChatLog.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể tải lịch sử CineBot.',
        ),
      );
    }
  }

  /// Xóa lịch sử hội thoại.
  ///
  /// DELETE /api/ai/history
  Future<void> clearHistory() async {
    try {
      final response = await _dio.delete(
        ApiConstants.aiHistory,
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Dữ liệu xóa lịch sử không hợp lệ.',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể xóa lịch sử trò chuyện.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể xóa lịch sử trò chuyện.',
        ),
      );
    }
  }

  String _getErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      final errors = responseData['errors'];

      if (errors is Map) {
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(
              value.map(
                (item) => item.toString(),
              ),
            );
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối đến máy chủ quá thời gian.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ.';

      case DioExceptionType.badCertificate:
        return 'Chứng chỉ máy chủ không hợp lệ.';

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 401) {
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }

        if (statusCode == 400) {
          return 'Yêu cầu gửi tới CineBot không hợp lệ.';
        }

        if (statusCode != null && statusCode >= 500) {
          return 'Máy chủ CineBot đang gặp sự cố.';
        }

        return defaultMessage;

      default:
        return defaultMessage;
    }
  }
}

class ChatResponse {
  final String reply;
  final List<Movie> recommendedMovies;
  final DateTime? createdAt;

  const ChatResponse({
    required this.reply,
    this.recommendedMovies = const <Movie>[],
    this.createdAt,
  });

  factory ChatResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawMovies = json['recommendedMovies'];

    final movies = <Movie>[];

    if (rawMovies is List) {
      for (final item in rawMovies) {
        if (item is Map) {
          try {
            movies.add(
              Movie.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (_) {
            // Bỏ qua movie không hợp lệ để không làm hỏng
            // toàn bộ câu trả lời của CineBot.
          }
        }
      }
    }

    return ChatResponse(
      reply: json['reply']?.toString() ?? '',
      recommendedMovies: movies,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,
    );
  }
}

