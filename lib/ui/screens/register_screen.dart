import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _idController = TextEditingController(); // Cedula/Placa
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _placaController = TextEditingController();

  String selectedRole = 'driver'; // Rol por defecto
  bool _isLoading = false;

  Future<void> _registrarse() async {
    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final pass = _passController.text.trim();
    final placa = _placaController.text.trim();

    if (name.isEmpty || id.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rellene los campos obligatorios")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // REGISTRO EN SUPABASE
      await Supabase.instance.client.auth.signUp(
        email: "$id@terminal.app",
        password: pass,
        data: {
          // Estos son los metadatos que lee nuestro disparador SQL
          'full_name': name,
          'role': selectedRole,
          'placa': selectedRole == 'driver' ? placa : 'N/A',
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("¡Éxito!"),
            content: const Text(
                "Usuario registrado correctamente. Ahora puede iniciar sesión."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"))
            ],
          ),
        ).then((value) => Navigator.pop(context)); // Volver al login
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Registro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.person_add,
                size: 80, color: AppColors.primaryBlue),
            const SizedBox(height: 20),

            // SELECTOR DE ROL (Muy importante)
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: "Tipo de Usuario"),
              items: const [
                DropdownMenuItem(
                    value: 'driver', child: Text("Conductor (Chofer)")),
                DropdownMenuItem(
                    value: 'fiscal', child: Text("Autoridad (Fiscal)")),
              ],
              onChanged: (val) => setState(() => selectedRole = val!),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: "Nombre Completo", prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                  labelText: "Usuario / Cédula", prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 15),

            if (selectedRole == 'driver') // Solo mostrar placa si es chofer
              TextField(
                controller: _placaController,
                decoration: const InputDecoration(
                    labelText: "Nro de Placa",
                    prefixIcon: Icon(Icons.bus_alert)),
              ),

            const SizedBox(height: 15),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Contraseña", prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _registrarse,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("FINALIZAR REGISTRO",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
