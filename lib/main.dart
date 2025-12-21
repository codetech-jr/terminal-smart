// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/app_theme.dart';
import 'ui/screens/driver_home.dart';
import 'ui/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAMOS SUPABASE CON TUS CONSTANTES
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const TerminalSmartApp());
}

class TerminalSmartApp extends StatelessWidget {
  const TerminalSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. REVISAR SI YA HAY SESIÓN ACTIVA EN EL TELÉFONO
    // Si currentSession tiene datos, el usuario ya entró antes y no ha cerrado sesión.
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TerminalSmart Charallave',
      theme: AppTheme.governmentTheme,

      // 3. LÓGICA DE RUTEO DIRECTA
      // Si está logueado -> Va directo al Home del conductor
      // Si NO está logueado -> Va al Login
      home: isLoggedIn ? const DriverHomeScreen() : const LoginScreen(),

      // Rutas nombradas (útiles para navegar desde otras pantallas)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DriverHomeScreen(),
      },
    );
  }
}
