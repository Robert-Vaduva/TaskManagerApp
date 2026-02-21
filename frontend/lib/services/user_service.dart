import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class UserService {
  final String baseUrl = "http://127.0.0.1:8000/users";

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

      // Citim bytes-ii fișierului (funcționează și pe Web și pe Mobil)
      List<int> imageBytes = await imageFile.readAsBytes();

      // Extragem extensia folosind pachetul path sau manual
      String extension = p.extension(imageFile.path).replaceAll('.', '').toLowerCase();
      if (extension.isEmpty) extension = 'jpg'; // fallback

      // Adăugăm fișierul folosind bytes în loc de path
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'avatar.$extension', // Numele de fișier este necesar pentru backend
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