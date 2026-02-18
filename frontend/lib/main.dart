import 'package:flutter/material.dart';
import 'package:frontend/pages/auth_page.dart';
import 'package:frontend/services/notification_service.dart'; // Importă noul serviciu

void main() async {
  // 1. Necesar pentru a rula cod asincron înainte de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inițializăm serviciul de notificări
  final notificationService = NotificationService();
  await notificationService.initNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevBros TaskManager',
      // Tema Light
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      // Tema Dark
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system, // Comută automat între Light/Dark bazat pe sistem
      home: const AuthPage(),
    );
  }
}