import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _serverMessage = "Aștept date de la server...";

  Future<void> fetchData() async {
    try {
      // Localhost pe Mac merge direct în Chrome
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/salut'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _serverMessage = data['data']['mesaj'];
        });
      }
    } catch (e) {
      setState(() {
        _serverMessage = "Eroare: Nu m-am putut conecta la server!";
      });
    }
  }

  Future<void> registerUser(String email, String name, String password) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/v1/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "full_name": name,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      print("Utilizator salvat în baza de date!");
    } else {
      print("Eroare la înregistrare: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DevBros Labs - App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_serverMessage, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: const Text("Cere date de la Backend"),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _statusMessage = "";

  Future<void> _handleRegister() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "full_name": _nameController.text,
          "password": _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _statusMessage = "Utilizator creat cu succes!");
      } else {
        final error = jsonDecode(response.body);
        setState(() => _statusMessage = "Eroare: ${error['detail']}");
      }
    } catch (e) {
      setState(() => _statusMessage = "Eroare de conexiune la server.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Înregistrare Nouă")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Nume Complet")),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _passController, decoration: InputDecoration(labelText: "Parolă"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _handleRegister, child: Text("Creează Cont")),
            SizedBox(height: 20),
            Text(_statusMessage, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true; // Toggle între Login și Register
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  // Funcția de trimitere date (Login sau Register)
  Future<void> _submit() async {
    setState(() { _isLoading = true; _message = ""; });

    final endpoint = isLogin ? 'login' : 'register';
    final url = Uri.parse('http://127.0.0.1:8000/api/v1/auth/$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passController.text,
          "full_name": isLogin ? "" : _nameController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (isLogin) {
            String token = data['access_token'];
            // Navigăm către Dashboard
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(email: _emailController.text, token: token),
              ),
            );
          } else {
          setState(() {
            _message = "Cont creat! Acum te poți loga.";
            isLogin = true; // Îl trimitem la login după înregistrare
          });
        }
      } else {
        setState(() => _message = "Eroare: ${data['detail']}");
      }
    } catch (e) {
      setState(() => _message = "Server inaccesibil. Verifică Backend-ul!");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(isLogin ? "Autentificare" : "Cont Nou",
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              if (!isLogin) ...[
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nume Complet", border: OutlineInputBorder())),
                const SizedBox(height: 15),
              ],
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passController, decoration: const InputDecoration(labelText: "Parolă", border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 25),

              _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(onPressed: _submit, child: Text(isLogin ? "Login" : "Înregistrare")),
                  ),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Nu ai cont? Creează unul" : "Ai deja cont? Loghează-te"),
              ),
              const SizedBox(height: 20),
              Text(_message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final String email;
  final String token;

  const DashboardPage({super.key, required this.email, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Comercial"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context), // Revine la Login
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.indigo),
                title: Text("Bine ai venit, $email"),
                subtitle: const Text("Status: Utilizator Autentificat"),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Acțiunile tale:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text("Vezi Produsele"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Istoric Comenzi"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}