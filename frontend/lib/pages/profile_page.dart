import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import 'package:http/http.dart' as http;
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
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  String _createdAt = "-";
  String _lastLogin = "-";

  final String _imageHost = "http://127.0.0.1:8000/";
  final String _defaultAvatarPath = "media/profile_pics/default_user.jpg";

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
      _showSnackBar("Nu s-au putut încărca datele.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse("${_imageHost}api/v1/auth/delete-account"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        _showSnackBar("Eroare la ștergerea contului.");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Eroare de conexiune la server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Schimbă Parola"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Parolă Nouă"),
                validator: (val) => (val == null || val.length < 8) ? "Minim 8 caractere" : null,
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmă Parola"),
                validator: (val) => val != passwordController.text ? "Parolele nu coincid" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _updatePasswordOnServer(passwordController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Actualizează"),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePasswordOnServer(String newPassword) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse("${_imageHost}users/me"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"password": newPassword}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Parola a fost actualizată cu succes!");
      } else {
        _showSnackBar("Eroare la actualizarea parolei.");
      }
    } catch (e) {
      _showSnackBar("Eroare de conexiune.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Șterge definitiv contul?"),
        content: const Text("Această acțiune este ireversibilă. Toate datele tale vor fi șterse definitiv."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anulează")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text("Șterge Contul", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                      const SizedBox(height: 16),
                      _buildDangerZone(theme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    String finalImageUrl = (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
        ? "$_imageHost$_profileImageUrl"
        : "$_imageHost$_defaultAvatarPath";

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
                    backgroundImage: NetworkImage(finalImageUrl),
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
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.lock_outline, color: theme.colorScheme.secondary),
            title: const Text("Parolă", style: TextStyle(fontSize: 14)),
            trailing: TextButton(
              onPressed: _showChangePasswordDialog,
              child: const Text("Schimbă"),
            ),
          ),
        ),
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

  Widget _buildDangerZone(ThemeData theme) {
    return InkWell(
      onTap: _confirmDeleteAccount,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Șterge Contul", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text("Acțiunea este ireversibilă", style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.red),
          ],
        ),
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
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}