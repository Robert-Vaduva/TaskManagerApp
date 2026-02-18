import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  String _message = "";

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    // Ajustează URL-ul: 10.0.2.2 pentru emulator Android, 127.0.0.1 pentru Web/Desktop
    //rova final String baseUrl = "http://127.0.0.1:8000/api/v1/auth";
    final String baseUrl = "http://192.168.178.112:8000/api/v1/auth";
    final url = Uri.parse(isLogin ? '$baseUrl/login' : '$baseUrl/register');

    try {
      http.Response response;

      if (isLogin) {
        // LOGIN: Trebuie să trimitem Form Data (x-www-form-urlencoded)
        response = await http.post(
          url,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: {
            "username": _emailController.text, // FastAPI caută 'username'
            "password": _passController.text,
          },
        );
      } else {
        // REGISTER: Trimitem JSON standard
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": _emailController.text,
            "password": _passController.text,
            "full_name": _nameController.text,
          }),
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isLogin) {
          String token = data['access_token'];
          // Navigăm și ștergem istoricul pentru a nu reveni la login cu butonul 'back'
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(
                  email: _emailController.text,
                  token: token,
                ),
              ),
            );
          }
        } else {
          setState(() {
            _message = "Cont creat cu succes! Te poți loga.";
            isLogin = true;
          });
        }
      } else {
        // Gestionare erori de la backend
        String error = data['detail'] is String ? data['detail'] : "Eroare validare date";
        setState(() => _message = error);
      }
    } catch (e) {
      setState(() => _message = "Nu mă pot conecta la server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.task_alt, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(isLogin ? "Bine ai revenit!" : "Creează un cont",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nume Complet", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Parolă", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 25),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: _submit,
                        child: Text(isLogin ? "Login" : "Înregistrare"),
                      ),
                    ),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Nu ai cont? Înregistrează-te" : "Ai deja cont? Loghează-te"),
              ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_message, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}