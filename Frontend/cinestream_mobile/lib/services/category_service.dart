import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';

class CategoryService {
  static const String _baseUrl =
      'http://10.0.2.2:5182/api';

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh mục: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể tải danh sách danh mục',
      );
    }

    final data =
        json['data'] as List<dynamic>;

    return data
        .map(
          (item) => Category.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Category> getCategoryById(
    int id,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh mục: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể tải danh mục',
      );
    }

    return Category.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }
}