import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskService {
  // Ajustează URL-ul în funcție de mediul de testare:
  // 127.0.0.1 pentru Web/Desktop, 10.0.2.2 pentru Emulator Android
  final String baseUrl = "http://127.0.0.1:8000/tasks";


  Future<List<Task>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 401) {
      // Aici poți folosi un Stream sau o notificare globală pentru Logout
      throw Exception('Sesiune expirată. Te rugăm să te loghezi din nou.');
    }

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Task.fromJson(data)).toList();
    } else {
      throw Exception('Eroare la încărcarea task-urilor: ${response.statusCode}');
    }
  }

  Future<Task> createTask(String token, String title, String description, String priority) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "priority": priority,
      }),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Eroare la crearea task-ului: ${response.body}');
    }
  }

  Future<void> updateTaskStatus(String token, int taskId, bool isCompleted) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "is_completed": isCompleted,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Eroare la actualizarea task-ului');
    }
  }

  Future<void> updateTask(String token, int taskId, String title, String description, String priority) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "priority": priority,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Eroare la editarea task-ului');
    }
  }

  Future<void> deleteTask(String token, int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Eroare la ștergerea task-ului');
    }
  }
}