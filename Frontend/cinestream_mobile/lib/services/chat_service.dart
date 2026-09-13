import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/movie.dart';
import 'auth_service.dart';

class ChatResponse {
  final String reply;
  final List<Movie> recommendedMovies;
  final DateTime createdAt;

  const ChatResponse({
    required this.reply,
    required this.recommendedMovies,
    required this.createdAt,
  });
}

class ChatMessage {
  final String text;
  final bool isFromBot;
  final DateTime? createdAt;
  final List<Movie> recommendedMovies;

  const ChatMessage({
    required this.text,
    required this.isFromBot,
    this.createdAt,
    this.recommendedMovies = const [],
  });
}

class ChatService {
  ChatService._();

  static final ChatService instance =
      ChatService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout:
          const Duration(seconds: 15),
      receiveTimeout:
          const Duration(seconds: 60),
      sendTimeout:
          const Duration(seconds: 15),
      headers: {
        'Content-Type':
            'application/json',
      },
    ),
  );

  Future<ChatResponse> sendMessage(
    String message,
  ) async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập để sử dụng CineBot.',
      );
    }

    final text = message.trim();

    if (text.isEmpty) {
      throw Exception(
        'Nội dung tin nhắn không được để trống.',
      );
    }

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.aiChat}',
        data: {
          'message': text,
        },
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token',
          },
        ),
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(body);

      final data =
          _asMap(body['data']);

      final reply =
          data['reply']
              ?.toString()
              .trim();

      if (reply == null ||
          reply.isEmpty) {
        throw Exception(
          'Backend không trả về câu trả lời từ CineBot.',
        );
      }

      final recommendedMovies =
          _parseRecommendedMovies(
        data['recommendedMovies'],
      );

      final createdAt =
          _parseDate(
                data['createdAt'],
              ) ??
              DateTime.now();

      return ChatResponse(
        reply: reply,
        recommendedMovies:
            recommendedMovies,
        createdAt: createdAt,
      );
    } on DioException catch (error) {
      throw Exception(
        _getDioErrorMessage(error),
      );
    }
  }

  Future<List<ChatMessage>> getHistory({
    int limit = 30,
  }) async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập để xem lịch sử chat.',
      );
    }

    if (limit <= 0) {
      limit = 30;
    }

    if (limit > 100) {
      limit = 100;
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.aiHistory}',
        queryParameters: {
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token',
          },
        ),
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(body);

      final rawData =
          body['data'];

      if (rawData is! List) {
        return const [];
      }

      final messages =
          <ChatMessage>[];

      for (final item in rawData) {
        if (item is! Map) {
          continue;
        }

        final map =
            Map<String, dynamic>.from(
          item,
        );

        final text =
            map['message']
                ?.toString()
                .trim();

        if (text == null ||
            text.isEmpty) {
          continue;
        }

        messages.add(
          ChatMessage(
            text: text,
            isFromBot:
                map['isFromAI'] == true,
            createdAt:
                _parseDate(
              map['createdAt'],
            ),
          ),
        );
      }

      return messages;
    } on DioException catch (error) {
      throw Exception(
        _getDioErrorMessage(error),
      );
    }
  }

  Future<void> clearHistory() async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập.',
      );
    }

    try {
      final response =
          await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.aiHistory}',
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token',
          },
        ),
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(body);
    } on DioException catch (error) {
      throw Exception(
        _getDioErrorMessage(error),
      );
    }
  }

  List<Movie> _parseRecommendedMovies(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    final movies =
        <Movie>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      try {
        final json =
            Map<String, dynamic>.from(
          item,
        );

        movies.add(
          Movie.fromJson(json),
        );
      } catch (_) {
        // Bỏ qua movie lỗi để các movie
        // còn lại vẫn được hiển thị.
      }
    }

    return movies;
  }

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value
        is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  void _ensureSuccess(
    Map<String, dynamic> body,
  ) {
    if (body.isEmpty) {
      throw Exception(
        'Backend trả về dữ liệu không hợp lệ.',
      );
    }

    final success =
        body['success'];

    if (success == false) {
      final message =
          body['message']
              ?.toString()
              .trim();

      throw Exception(
        message == null ||
                message.isEmpty
            ? 'Yêu cầu không thành công.'
            : message,
      );
    }
  }

  String _getDioErrorMessage(
    DioException error,
  ) {
    final responseData =
        error.response?.data;

    if (responseData is Map) {
      final body =
          _asMap(responseData);

      final message =
          body['message']
              ?.toString()
              .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }

      final errors =
          body['errors'];

      if (errors is Map) {
        for (final value
            in errors.values) {
          if (value is List &&
              value.isNotEmpty) {
            return value.first
                .toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Kết nối tới CineBot quá lâu. Vui lòng thử lại.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối tới backend CineStream.';

      case DioExceptionType.badResponse:
        final statusCode =
            error.response?.statusCode;

        if (statusCode == 400) {
          return 'Yêu cầu Chat không hợp lệ.';
        }

        if (statusCode == 401) {
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }

        if (statusCode == 403) {
          return 'Bạn không có quyền sử dụng CineBot.';
        }

        if (statusCode == 500) {
          return 'Backend CineBot đang gặp lỗi. Vui lòng thử lại.';
        }

        return 'Backend trả về lỗi HTTP ${statusCode ?? ''}.';

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';

      case DioExceptionType.badCertificate:
        return 'Không thể xác thực chứng chỉ kết nối.';

      case DioExceptionType.unknown:
        return 'Không thể gửi tin nhắn tới CineBot.';
    }
  }
}