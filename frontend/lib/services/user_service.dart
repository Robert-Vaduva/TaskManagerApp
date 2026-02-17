import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://127.0.0.1:8000/users"; // Ajustează IP-ul pentru platforma ta

  Future<Map<String, dynamic>?> updateProfile(String token, String email, String fullName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "full_name": fullName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }
}