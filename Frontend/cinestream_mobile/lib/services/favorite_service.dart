import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/favorite.dart';
import 'auth_service.dart';

class FavoriteStatus {
  final bool isFavorite;

  const FavoriteStatus({
    required this.isFavorite,
  });
}

class FavoriteService {
  FavoriteService._();

  static final FavoriteService instance =
      FavoriteService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout:
          const Duration(seconds: 15),
      receiveTimeout:
          const Duration(seconds: 30),
      sendTimeout:
          const Duration(seconds: 15),
      headers: {
        'Content-Type':
            'application/json',
      },
    ),
  );

  Future<List<Favorite>> getFavorites() async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập để xem phim yêu thích.',
      );
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.favorites}',
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

      final data = body['data'];

      if (data is! List) {
        return const [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Favorite.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _getErrorMessage(error),
      );
    }
  }

  Future<bool> checkFavorite(
    int movieId,
  ) async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      return false;
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.favorites}/check/$movieId',
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

      return data['isFavorite'] == true;
    } on DioException catch (error) {
      throw Exception(
        _getErrorMessage(error),
      );
    }
  }

  Future<bool> addFavorite(
    int movieId,
  ) async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập để thêm phim yêu thích.',
      );
    }

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.favorites}/$movieId',
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

      return body['data'] != false;
    } on DioException catch (error) {
      throw Exception(
        _getErrorMessage(error),
      );
    }
  }

  Future<bool> removeFavorite(
    int movieId,
  ) async {
    final token =
        await AuthService.instance.getToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập để bỏ phim yêu thích.',
      );
    }

    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.favorites}/$movieId',
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

      return false;
    } on DioException catch (error) {
      throw Exception(
        _getErrorMessage(error),
      );
    }
  }

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  void _ensureSuccess(
    Map<String, dynamic> body,
  ) {
    if (body.isEmpty) {
      throw Exception(
        'Backend trả về dữ liệu không hợp lệ.',
      );
    }

    if (body['success'] == false) {
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

  String _getErrorMessage(
    DioException error,
  ) {
    final data =
        error.response?.data;

    if (data is Map) {
      final body =
          _asMap(data);

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
            return value.first.toString();
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
        return 'Kết nối tới backend quá lâu. Vui lòng thử lại.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối tới backend CineStream.';

      case DioExceptionType.badResponse:
        final status =
            error.response?.statusCode;

        if (status == 401) {
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }

        if (status == 403) {
          return 'Bạn không có quyền thực hiện thao tác này.';
        }

        if (status == 404) {
          return 'Không tìm thấy bộ phim.';
        }

        return 'Backend trả về lỗi HTTP ${status ?? ''}.';

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';

      case DioExceptionType.badCertificate:
        return 'Không thể xác thực chứng chỉ kết nối.';

      case DioExceptionType.unknown:
        return 'Không thể thực hiện thao tác yêu thích.';
    }
  }
}