import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MovieService {
  static const String _baseUrl =
      'http://10.0.2.2:5182/api';

  Future<List<Movie>> getMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách phim: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Không thể tải danh sách phim',
      );
    }

    final data =
        json['data'] as Map<String, dynamic>;

    final items =
        data['items'] as List<dynamic>;

    return items
        .map(
          (item) => Movie.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}