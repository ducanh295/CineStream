import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/favorite.dart';

class FavoriteService {
  FavoriteService._internal();

  static final FavoriteService instance =
      FavoriteService._internal();

  final Dio _dio = ApiClient.instance.dio;

  // ==============================================================
  // GET /api/favorites
  // ==============================================================

  Future<List<Favorite>> getFavorites() async {
    try {
      final response = await _dio.get(
        ApiConstants.favorites,
      );

      final body = _normalizeBody(
        response.data,
      );

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể tải danh sách phim yêu thích.',
        );
      }

      final data = body['data'];

      if (data == null) {
        return <Favorite>[];
      }

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => Favorite.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      throw Exception(
        'Dữ liệu Favorites từ Backend không hợp lệ.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // GET /api/favorites/check/{movieId}
  // ==============================================================

  Future<bool> checkFavorite(
    int movieId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.favorites}/check/$movieId',
      );

      final body = _normalizeBody(
        response.data,
      );

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể kiểm tra trạng thái yêu thích.',
        );
      }

      final data = body['data'];

      // Backend trả FavoriteStatusDto.
      //
      // Ví dụ:
      // {
      //   "success": true,
      //   "data": {
      //      "isFavorite": true
      //   }
      // }
      if (data is Map) {
        final map =
            Map<String, dynamic>.from(
          data,
        );

        final value =
            map['isFavorite'] ??
            map['favorite'] ??
            map['exists'] ??
            map['isLiked'];

        if (value is bool) {
          return value;
        }

        if (value is num) {
          return value.toInt() == 1;
        }

        if (value is String) {
          return _parseBool(value);
        }
      }

      // Hỗ trợ trường hợp Backend trả trực tiếp bool.
      if (data is bool) {
        return data;
      }

      if (data is num) {
        return data.toInt() == 1;
      }

      if (data is String) {
        return _parseBool(data);
      }

      throw Exception(
        'Không xác định được trạng thái phim yêu thích từ Backend.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // POST /api/favorites/{movieId}
  // ==============================================================

  Future<bool> addFavorite(
    int movieId,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.favorites}/$movieId',
      );

      final body = _normalizeBody(
        response.data,
      );

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể thêm phim vào danh sách yêu thích.',
        );
      }

      final data = body['data'];

      // Backend trả ApiResponse<bool>.
      if (data is bool) {
        return data;
      }

      // Nếu Backend không trả bool,
      // kiểm tra lại trạng thái thực tế.
      return await checkFavorite(
        movieId,
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // DELETE /api/favorites/{movieId}
  // ==============================================================

  Future<bool> removeFavorite(
    int movieId,
  ) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.favorites}/$movieId',
      );

      final body = _normalizeBody(
        response.data,
      );

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể bỏ phim khỏi danh sách yêu thích.',
        );
      }

      final data = body['data'];

      // Backend trả ApiResponse<bool>.
      if (data is bool) {
        return data;
      }

      // Kiểm tra lại Backend.
      return await checkFavorite(
        movieId,
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // TOGGLE
  // ==============================================================
  //
  // Backend KHÔNG có:
  // POST /api/favorites/toggle/{id}
  //
  // Vì vậy Flutter sẽ tự quyết định:
  //
  // chưa yêu thích -> POST
  // đã yêu thích   -> DELETE
  //
  // Sau đó kiểm tra lại bằng GET /check/{id}.
  // ==============================================================

  Future<bool> toggleFavorite(
    int movieId,
  ) async {
    try {
      final currentState =
          await checkFavorite(
        movieId,
      );

      if (currentState) {
        await removeFavorite(
          movieId,
        );
      } else {
        await addFavorite(
          movieId,
        );
      }

      // Đồng bộ lại trạng thái thực tế.
      return await checkFavorite(
        movieId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==============================================================
  // HELPERS
  // ==============================================================

  Map<String, dynamic> _normalizeBody(
    dynamic data,
  ) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(
        data,
      );
    }

    throw Exception(
      'Response từ Backend không hợp lệ.',
    );
  }

  bool _parseBool(
    String value,
  ) {
    final normalized =
        value.toLowerCase().trim();

    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no') {
      return false;
    }

    throw Exception(
      'Giá trị trạng thái Favorite không hợp lệ: "$value"',
    );
  }

  // ==============================================================
  // ERROR HANDLER
  // ==============================================================

  String _getErrorMessage(
    DioException error,
  ) {
    final statusCode =
        error.response?.statusCode;

    final responseData =
        error.response?.data;

    String responseText = '';

    if (responseData is Map) {
      final map =
          Map<String, dynamic>.from(
        responseData,
      );

      final message =
          map['message'] ??
          map['error'] ??
          map['title'] ??
          map['detail'];

      if (message != null &&
          message
              .toString()
              .trim()
              .isNotEmpty) {
        responseText =
            message.toString();
      }

      if (responseText.isEmpty &&
          map['errors'] != null) {
        responseText =
            map['errors'].toString();
      }

      if (responseText.isEmpty) {
        responseText =
            map.toString();
      }
    } else if (responseData != null) {
      responseText =
          responseData.toString();
    }

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi 400: $responseText'
              : 'API Favorites lỗi 400: Request không hợp lệ.';

        case 401:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi 401: $responseText'
              : 'API Favorites lỗi 401: Bạn chưa đăng nhập hoặc token không hợp lệ.';

        case 403:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi 403: $responseText'
              : 'API Favorites lỗi 403: Bạn không có quyền thực hiện thao tác này.';

        case 404:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi 404: $responseText'
              : 'API Favorites lỗi 404: Không tìm thấy endpoint hoặc phim.';

        case 500:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi 500: $responseText'
              : 'API Favorites lỗi 500: Backend đang xảy ra lỗi.';

        default:
          return responseText.isNotEmpty
              ? 'API Favorites lỗi HTTP $statusCode: $responseText'
              : 'API Favorites lỗi HTTP $statusCode.';
      }
    }

    if (error.type ==
        DioExceptionType.connectionTimeout) {
      return 'Kết nối Backend bị timeout.';
    }

    if (error.type ==
        DioExceptionType.sendTimeout) {
      return 'Gửi request tới Backend bị timeout.';
    }

    if (error.type ==
        DioExceptionType.receiveTimeout) {
      return 'Backend phản hồi quá chậm.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Không thể kết nối tới Backend. Hãy kiểm tra Backend đang chạy.';
    }

    return 'Lỗi gọi API Favorites: '
        '${error.message ?? error.toString()}';
  }
}

