import 'package:flutter/material.dart';
import '../services/user_service.dart'; // Asigură-te că importul este corect
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final String token; // 1. Adăugat token pentru API

  const ProfilePage({super.key, required this.email, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 2. Instanțiem serviciul
  final UserService _userService = UserService();

  late TextEditingController _emailController;
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isLoading = false; // Pentru feedback vizual la salvare

  final String _lastLogin = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}";

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController(text: ""); // Începem cu gol
    _loadUserData(); // Chemăm funcția de încărcare
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final data = await _userService.getProfile(widget.token);
    if (data != null) {
      setState(() {
        _emailController.text = data['email'] ?? widget.email;
        // Dacă full_name e null în DB, punem email-ul ca backup
        _nameController.text = data['full_name'] ?? widget.email.split('@')[0];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 3. Metodă unificată pentru toggle și salvare
  void _toggleEdit() async {
    if (_isEditing) {
      await _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final result = await _userService.updateProfile(
      widget.token, // Folosim widget.token din clasa părinte
      _emailController.text,
      _nameController.text,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      _showSnackBar("Profil actualizat cu succes!");
      setState(() => _isEditing = false);
    } else {
      _showSnackBar("Eroare la salvare. Verificați datele sau conexiunea.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilul Meu"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildPersonalDetails(),
            const SizedBox(height: 20),
            _buildSystemInfo(),
            const SizedBox(height: 30),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  // Folosim numele pentru a genera un avatar dinamic
                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${_nameController.text}&background=random'),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      onPressed: () => _showSnackBar("Funcție upload imagine indisponibilă momentan"),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (!_isEditing)
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: "Nume Complet",
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DETALII PERSONALE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildEditableField(Icons.email_outlined, "Email", _emailController),
        ],
      ),
    );
  }

  Widget _buildEditableField(IconData icon, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: controller,
                  enabled: _isEditing,
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SECURITATE & SISTEM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildStaticInfo(Icons.history, "Ultimul login", _lastLogin),
          const SizedBox(height: 10),
          _buildStaticInfo(Icons.security, "Tip Cont", "Utilizator Verificat"),
        ],
      ),
    );
  }

  Widget _buildStaticInfo(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo.shade300),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("DECONECTARE", style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ieșire cont"),
        content: const Text("Ești sigur că vrei să te deconectezi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthPage()), (route) => false),
            child: const Text("Deconectare", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}