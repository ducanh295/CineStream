import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/movie.dart';
import '../models/paged_result.dart';

class MovieService {
  MovieService._();

  static final MovieService instance = MovieService._();

  final Dio _dio = ApiClient.instance.dio;

  // Lấy danh sách phim phân trang đầy đủ bao gồm tổng số lượng và thông tin trang
  Future<PagedResult<Movie>> getPagedMovies({
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final trimmedSearch = search?.trim();

    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (categoryId != null) {
      queryParameters['categoryId'] = categoryId;
    }

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
    }

    try {
      final response = await _dio.get(
        ApiConstants.movies,
        queryParameters: queryParameters,
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Dữ liệu phim trả về không hợp lệ.',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể tải danh sách phim.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        return PagedResult.empty();
      }

      final items = data['items'];
      final totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
      final pageNumber = (data['pageNumber'] as num?)?.toInt() ?? page;
      final size = (data['pageSize'] as num?)?.toInt() ?? pageSize;
      final totalPages = (data['totalPages'] as num?)?.toInt() ??
          (size > 0 ? (totalCount / size).ceil() : 0);

      final movies = (items is List)
          ? items
              .whereType<Map>()
              .map(
                (item) => Movie.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <Movie>[];

      return PagedResult<Movie>(
        items: movies,
        totalCount: totalCount,
        pageNumber: pageNumber,
        pageSize: size,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể kết nối đến máy chủ.',
        ),
      );
    }
  }

  // Lấy danh sách phim thông thường (tương thích ngược với các chức năng sẵn có)
  Future<List<Movie>> getMovies({
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final paged = await getPagedMovies(
      categoryId: categoryId,
      search: search,
      page: page,
      pageSize: pageSize,
    );
    return paged.items;
  }

Future<List<Movie>> getFeaturedMovies({int limit = 5}) async {
  try {
    final response = await _dio.get(
      '${ApiConstants.movies}/featured',
      queryParameters: {'limit': limit},
    );

    final body = response.data;
    if (body is! Map || body['success'] != true) {
      return const [];
    }

    final data = body['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Movie.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } catch (_) {
    return const [];
  }
}

Future<Movie> getMovieById(int id) async {
try {
final response = await _dio.get(
'${ApiConstants.movies}/$id',
);


  final body = response.data;

  if (body is! Map) {
    throw Exception(
      'Dữ liệu phim không hợp lệ.',
    );
  }

  if (body['success'] != true) {
    throw Exception(
      body['message']?.toString() ??
          'Không tìm thấy phim.',
    );
  }

  final data = body['data'];

  if (data is! Map) {
    throw Exception(
      'Dữ liệu chi tiết phim không hợp lệ.',
    );
  }

  return Movie.fromJson(
    Map<String, dynamic>.from(data),
  );
} on DioException catch (e) {
  throw Exception(
    _getErrorMessage(
      e,
      'Không thể tải chi tiết phim.',
    ),
  );
}


}

Future<MoviePlayback> getPlayback(int id) async {
try {
final response = await _dio.get(
'${ApiConstants.movies}/$id/playback',
);


  final body = response.data;

  if (body is! Map) {
    throw Exception(
      'Dữ liệu playback không hợp lệ.',
    );
  }

  if (body['success'] != true) {
    throw Exception(
      body['message']?.toString() ??
          'Không thể lấy luồng phát.',
    );
  }

  final data = body['data'];

  if (data is! Map) {
    throw Exception(
      'Dữ liệu playback không hợp lệ.',
    );
  }

  return MoviePlayback.fromJson(
    Map<String, dynamic>.from(data),
  );
} on DioException catch (e) {
  throw Exception(
    _getErrorMessage(
      e,
      'Không thể lấy thông tin phát video.',
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

  default:
    return defaultMessage;
}


}
}

class MoviePlayback {
final int movieId;
final String title;
final String? streamUrl;
final String streamType;
final int videoStatus;
final int? duration;

const MoviePlayback({
required this.movieId,
required this.title,
this.streamUrl,
this.streamType = 'NONE',
this.videoStatus = 0,
this.duration,
});

factory MoviePlayback.fromJson(
Map<String, dynamic> json,
) {
return MoviePlayback(
movieId: (json['movieId'] as num?)?.toInt() ?? 0,
title: json['title']?.toString() ?? '',
streamUrl: json['streamUrl']?.toString(),
streamType: json['streamType']?.toString() ?? 'NONE',
videoStatus:
(json['videoStatus'] as num?)?.toInt() ?? 0,
duration:
(json['duration'] as num?)?.toInt(),
);
}
}
