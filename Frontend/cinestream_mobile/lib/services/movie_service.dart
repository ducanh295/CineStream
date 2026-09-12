import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/movie.dart';

class MovieService {
MovieService._();

static final MovieService instance = MovieService._();

final Dio _dio = ApiClient.instance.dio;

Future<List<Movie>> getMovies({
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
    return const [];
  }

  final items = data['items'];

  if (items is! List) {
    return const [];
  }

  return items
      .whereType<Map>()
      .map(
        (item) => Movie.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
} on DioException catch (e) {
  throw Exception(
    _getErrorMessage(
      e,
      'Không thể kết nối đến máy chủ.',
    ),
  );
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
