import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../services/api_config.dart';


class CategoryService {
  final String baseUrl = "${ApiConfig.baseUrl}/categories";

  Future<List<Category>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    }
    return [];
  }

  Future<Category?> createCategory(String token, String name, String color) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"name": name, "color": color}),
    );

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Category?> updateCategory(
      String token, int categoryId, String? name, String? color) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$categoryId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        if (name != null) "name": name,
        if (color != null) "color": color,
      }),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteCategory(String token, int categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$categoryId'),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 204;
  }
}