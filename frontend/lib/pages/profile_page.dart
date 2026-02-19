import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final String token;

  const ProfilePage({super.key, required this.email, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isLoading = false;

  final String _lastLogin = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}";

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController(text: "");
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final data = await _userService.getProfile(widget.token);
    if (data != null) {
      setState(() {
        _emailController.text = data['email'] ?? widget.email;
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

  void _toggleEdit() async {
    if (_isEditing) {
      await _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final result = await _userService.updateProfile(widget.token, _emailController.text, _nameController.text);
    setState(() => _isLoading = false);

    if (result != null) {
      _showSnackBar("Profil actualizat!");
      setState(() => _isEditing = false);
    } else {
      _showSnackBar("Eroare la salvare.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculăm o margine adaptivă: 10% din ecran, dar nu mai puțin de 16px
    double horizontalPadding = screenWidth * 0.10;
    if (horizontalPadding < 16) horizontalPadding = 16;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Profilul Meu"),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildProfileHeader(theme),
                const SizedBox(height: 30),
                _buildPersonalDetails(theme),
                const SizedBox(height: 25),
                _buildSystemInfo(theme),
                const SizedBox(height: 40),
                _buildLogoutButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer, // Culoare mai discretă pentru header-ul încapsulat
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: theme.colorScheme.primary,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${_nameController.text}&background=random'),
            ),
          ),
          const SizedBox(height: 20),
          if (!_isEditing)
            Text(
              _nameController.text,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: theme.colorScheme.onPrimaryContainer),
                decoration: InputDecoration(
                  hintText: "Nume Complet",
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DETALII PERSONALE",
             style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.2)),
        const SizedBox(height: 15),
        _buildEditableField(theme, Icons.email_outlined, "Email", _emailController),
      ],
    );
  }

  Widget _buildEditableField(ThemeData theme, IconData icon, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: controller,
                  enabled: _isEditing,
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SECURITATE & SISTEM",
             style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.2)),
        const SizedBox(height: 15),
        _buildStaticInfo(theme, Icons.history, "Ultimul login", _lastLogin),
        const SizedBox(height: 10),
        _buildStaticInfo(theme, Icons.security, "Tip Cont", "Utilizator Verificat"),
      ],
    );
  }

  Widget _buildStaticInfo(ThemeData theme, IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.secondary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _confirmLogout,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text("DECONECTARE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        side: const BorderSide(color: Colors.red, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deconectare"),
        content: const Text("Ești sigur că vrei să părăsești contul?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthPage()), (route) => false),
            child: const Text("Deconectare"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}