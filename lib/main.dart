import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_service.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(ApiClient.tokenKey);
  if (token != null) {
    AuthStore.instance.setToken(token);
  }
  runApp(const PgmApp());
}

class PgmApp extends StatelessWidget {
  const PgmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PG Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: AuthStore.instance.isAuthenticated
          ? const HomeShell()
          : const LoginScreen(),
    );
  }
}
