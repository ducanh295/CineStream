import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/favorite.dart';

class FavoriteService {
  static const String _baseUrl =
      'http://10.0.2.2:5182/api';

  Future<List<Favorite>> getFavorites(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách yêu thích: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể tải danh sách yêu thích',
      );
    }

    final dynamic data = json['data'];

    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) => Favorite.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> checkFavorite(
    String token,
    int movieId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/favorites/check/$movieId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể kiểm tra trạng thái yêu thích: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể kiểm tra trạng thái yêu thích',
      );
    }

    final data = json['data'];

    if (data is! Map<String, dynamic>) {
      return false;
    }

    return data['isFavorite'] == true;
  }

  Future<bool> addFavorite(
    String token,
    int movieId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/favorites/$movieId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể thêm phim vào danh sách yêu thích: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể thêm phim vào danh sách yêu thích',
      );
    }

    return json['data'] == true;
  }

  Future<bool> removeFavorite(
    String token,
    int movieId,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/favorites/$movieId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể xóa phim khỏi danh sách yêu thích: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể xóa phim khỏi danh sách yêu thích',
      );
    }

    return json['data'] == true;
  }
}