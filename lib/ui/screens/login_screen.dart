// lib/ui/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import 'driver_home.dart';
import 'validator_screen.dart';
import 'register_screen.dart'; // <--- NUEVO IMPORT: Necesario para navegar al registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController =
      TextEditingController(); // Cédula, Placa o Email completo
  final _passController = TextEditingController();
  bool _isLoading = false;

  // LÓGICA DE INICIO DE SESIÓN
  Future<void> _iniciarSesion() async {
    // 1. Limpiamos espacios al inicio y final
    final idInput = _idController.text.trim();
    final password = _passController.text.trim();

    if (idInput.isEmpty || password.isEmpty) {
      _mostrarError("Ingrese todos los datos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. LÓGICA INTELIGENTE DE EMAIL:
      String emailFinal;
      if (!idInput.contains('@')) {
        emailFinal = "$idInput@terminal.app";
      } else {
        emailFinal = idInput;
      }

      // 3. AUTENTICACIÓN
      final AuthResponse res =
          await Supabase.instance.client.auth.signInWithPassword(
        email: emailFinal,
        password: password,
      );

      if (res.user != null) {
        // 4. VERIFICACIÓN DE ROL
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', res.user!.id)
            .single();

        final role = profileData['role'];

        if (mounted) {
          // 5. DIRECCIONAMIENTO INTELIGENTE
          Widget nextScreen;

          if (role == 'fiscal') {
            nextScreen = const ValidatorScreen();
          } else {
            nextScreen = const DriverHomeScreen();
          }

          // Navegamos
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => nextScreen));
        }
      }
    } on AuthException catch (e) {
      _mostrarError(e.message);
    } catch (e) {
      _mostrarError("Error de conexión o credenciales inválidas");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.alertRed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo Azul Institucional
          Container(color: AppColors.primaryBlue),

          // 2. Decoración curvada arriba
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Contenido Central (Tarjeta)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO / ICONO
                      const Icon(Icons.shield,
                          size: 60, color: AppColors.primaryBlue),
                      const SizedBox(height: 10),
                      const Text("TERMINAL SMART",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue)),
                      const SizedBox(height: 5),
                      Text("Acceso de Control",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 10),

                      // LINEA TRICOLOR DECORATIVA
                      Container(
                          height: 3,
                          width: 40,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                            Color(0xFFFFC107),
                            Color(0xFF003875),
                            Color(0xFFD32F2F)
                          ]))),

                      const SizedBox(height: 30),

                      // INPUT ID
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                            labelText: "Usuario / Placa",
                            prefixIcon: const Icon(Icons.badge,
                                color: AppColors.textGrey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15)),
                      ),
                      const SizedBox(height: 15),

                      // INPUT CONTRASEÑA
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon:
                              const Icon(Icons.lock, color: AppColors.textGrey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // BOTÓN ENTRAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentYellow,
                            foregroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.primaryBlue)
                              : const Text("INICIAR TURNO",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      // --- AQUÍ ESTÁ EL CAMBIO ---
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()));
                        },
                        child: const Text("¿No tiene cuenta? Regístrese aquí",
                            style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ),
                      // ---------------------------
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pie de pagina
          const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                  child: Text("Solo Personal Autorizado",
                      style: TextStyle(color: Colors.white54, fontSize: 12))))
        ],
      ),
    );
  }
}
