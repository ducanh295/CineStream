import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/category.dart';

class CategoryService {
CategoryService._();

static final CategoryService instance = CategoryService._();

final Dio _dio = ApiClient.instance.dio;

Future<List<Category>> getCategories() async {
try {
final response = await _dio.get(
ApiConstants.categories,
);


  final body = response.data;

  if (body is! Map) {
    throw Exception(
      'Dữ liệu thể loại trả về không hợp lệ.',
    );
  }

  if (body['success'] != true) {
    throw Exception(
      body['message']?.toString() ??
          'Không thể tải danh sách thể loại.',
    );
  }

  final data = body['data'];

  if (data is! List) {
    return const [];
  }

  return data
      .whereType<Map>()
      .map(
        (item) => Category.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
} on DioException catch (e) {
  final message = e.response?.data is Map
      ? e.response?.data['message']?.toString()
      : null;

  throw Exception(
    message ?? 'Không thể kết nối đến máy chủ.',
  );
}


}
}
