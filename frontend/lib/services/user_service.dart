import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'package:path/path.dart' as p;
import '../services/api_config.dart';

class UserService {
  final String baseUrl = "${ApiConfig.baseUrl}/users";

  Future<User?> updateProfile({
    required String token,
    String? email,
    String? fullName,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          if (email != null) "email": email,
          if (fullName != null) "full_name": fullName,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Eroare updateProfile: $e");
      return null;
    }
  }

  Future<User?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Eroare getProfile: $e");
      return null;
    }
  }

  Future<String?> uploadProfilePicture(String token, XFile imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/me/upload-avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      List<int> imageBytes = await imageFile.readAsBytes();

      String extension = p.extension(imageFile.path).replaceAll('.', '').toLowerCase();
      if (extension.isEmpty) extension = 'jpg';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'avatar.$extension',
        contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print("Eroare uploadProfilePicture: $e");
      return null;
    }
  }
}