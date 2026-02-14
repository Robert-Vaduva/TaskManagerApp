import 'package:flutter/material.dart';
import 'auth_page.dart';

class ProfilePage extends StatelessWidget {
  final String email;

  const ProfilePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilul Meu"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            email,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text("Membru DevBros", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          const Divider(),
          _buildProfileOption(Icons.settings, "Setări", () {}),
          _buildProfileOption(Icons.help_outline, "Ajutor & Suport", () {}),
          _buildProfileOption(Icons.logout, "Deconectare", () {
            // Deoarece nu avem shared_preferences, doar navigăm înapoi la Auth
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
            );
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.indigo),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}