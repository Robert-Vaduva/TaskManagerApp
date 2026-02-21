import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../models/user_model.dart'; // Asigură-te că ai acest import
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
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController; // Nou

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  String _createdAt = "-";
  String _lastLogin = "-";

  // URL-ul de bază pentru imagini (schimbă cu IP-ul tău dacă e pe telefon real)
  final String _imageHost = "http://127.0.0.1:8000/";

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "Niciodată";
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getProfile(widget.token);
      if (user != null) {
        setState(() {
          _emailController.text = user.email;
          _nameController.text = user.fullName ?? "";
          _profileImageUrl = user.profileImageUrl;
          _createdAt = _formatDateTime(user.createdAt);
          _lastLogin = _formatDateTime(user.lastLogin);
        });
      }
    } catch (e) {
      print("Eroare UI load: $e");
      _showSnackBar("Nu s-au putut încărca datele.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
    final result = await _userService.updateProfile(
      token: widget.token,
      email: _emailController.text,
      fullName: _nameController.text,
    );
    setState(() => _isLoading = false);

    if (result != null) {
      _showSnackBar("Profil actualizat!");
      setState(() => _isEditing = false);
    } else {
      _showSnackBar("Eroare la salvare.");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      // Trimitem pickedFile direct (XFile), fără File(pickedFile.path)
      String? newUrl = await _userService.uploadProfilePicture(widget.token, pickedFile);

      setState(() => _isLoading = false);

      if (newUrl != null) {
        setState(() => _profileImageUrl = newUrl);
        _showSnackBar("Imagine actualizată!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.10 > 16 ? screenWidth * 0.10 : 16;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Profilul Meu"),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: theme.colorScheme.primary,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage("$_imageHost$_profileImageUrl")
                        : NetworkImage('https://ui-avatars.com/api/?name=${_nameController.text}&background=random') as ImageProvider,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!_isEditing)
            Text(
              _nameController.text.isEmpty ? "Utilizator" : _nameController.text,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: "Nume Complet"),
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
        Text("DETALII PERSONALE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const SizedBox(height: 15),
        _buildEditableField(theme, Icons.email_outlined, "Email", _emailController),
        const SizedBox(height: 10),
        _buildEditableField(theme, Icons.phone_outlined, "Telefon", _phoneController),
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
        Text("SECURITATE & SISTEM", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const SizedBox(height: 15),
        _buildStaticInfo(theme, Icons.calendar_today, "Membru din", _createdAt),
        const SizedBox(height: 10),
        _buildStaticInfo(theme, Icons.history, "Ultimul login", _lastLogin),
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