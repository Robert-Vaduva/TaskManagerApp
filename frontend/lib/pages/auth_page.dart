import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'dashboard_page.dart';
import 'package:frontend/services/api_config.dart';


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
  bool _isSuccess = false;

  final String baseUrl = "${ApiConfig.baseUrl}/api/v1/auth";

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _message = "";
      _isSuccess = false;
    });

    final url = Uri.parse(isLogin ? '$baseUrl/login' : '$baseUrl/register');

    try {
      http.Response response;
      if (isLogin) {
        response = await http.post(
          url,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: {"username": _emailController.text, "password": _passController.text},
        );
      } else {
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
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(email: _emailController.text, token: token)),
            );
          }
        } else {
          setState(() {
            _message = "Cont creat cu succes! Te poți loga.";
            _isSuccess = true;
            isLogin = true;
          });
        }
      } else {
        setState(() {
          _message = data['detail'] is String ? data['detail'] : "Eroare date";
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = "Eroare de conexiune la server.";
        _isSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding = screenWidth * 0.10;
    if (horizontalPadding < 16) horizontalPadding = 16;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/Login_animation.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogin ? "Bine ai revenit!" : "Creează un cont",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!isLogin) ...[
                    _buildTextField(_nameController, "Nume Complet", Icons.person_outline),
                    const SizedBox(height: 15),
                  ],
                  _buildTextField(_emailController, "Email", Icons.email_outlined),
                  const SizedBox(height: 15),
                  _buildTextField(_passController, "Parolă", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: _submit,
                            child: Text(
                              isLogin ? "LOGARE" : "ÎNREGISTRARE",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => setState(() {
                      isLogin = !isLogin;
                      _message = "";
                    }),
                    child: Text(
                      isLogin ? "Nu ai cont? Înregistrează-te" : "Ai deja cont? Loghează-te",
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                  if (_message.isNotEmpty) _buildFeedbackMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.8),
      ),
    );
  }

  Widget _buildFeedbackMessage() {
    final Color contentColor = _isSuccess ? Colors.green : Colors.redAccent;
    final IconData icon = _isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: contentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: contentColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: contentColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _message,
                style: TextStyle(color: contentColor, fontWeight: FontWeight.w600, fontSize: 14)
              ),
            ),
          ],
        ),
      ),
    );
  }
}