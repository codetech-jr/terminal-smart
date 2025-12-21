// lib/ui/screens/driver_home.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_theme.dart';
import 'validator_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // --- LÓGICA DE BACKEND (SUPABASE) ---
  final _supabase = Supabase.instance.client;

  // VARIABLE DINÁMICA: ID del usuario logueado
  late String currentDriverId;

  // VARIABLE NUEVA: Nombre del conductor traído de la BD
  String nombreConductor = "Cargando nombre...";

  // VARIABLE PARA EL QR: Ticket ID
  String? qrDataSeguro;

  // --- VARIABLES DE ESTADO ---
  bool isLoading = true;
  double saldo = 0.00;
  bool isBalanceVisible = true;
  final double costoSalida = 40.00;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  // 1. VERIFICAR AUTENTICACIÓN
  void _checkCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      currentDriverId = user.id;
      _fetchSaldoReal(); // Busca saldo Y perfil
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  // 2. TRAER SALDO Y PERFIL (JOIN)
  Future<void> _fetchSaldoReal() async {
    try {
      // MAGIA SQL: Traemos 'balance' de wallets Y 'full_name' de profiles
      // usando la relación de llave foránea (user_id).
      final data = await _supabase
          .from('wallets')
          .select('balance, profiles(full_name, placa)')
          .eq('user_id', currentDriverId)
          .single();

      if (mounted) {
        setState(() {
          // 1. Actualizar Saldo
          saldo = data['balance'].toDouble();

          // 2. Actualizar Nombre (Extrayendo del JSON anidado)
          // data['profiles'] puede ser un mapa.
          if (data['profiles'] != null) {
            final perfil = data['profiles'] as Map<String, dynamic>;
            nombreConductor = perfil['full_name'] ?? "Conductor Sin Nombre";
            // Si quisieras usar la placa: String placa = perfil['placa'];
          }

          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error cargando datos: $error');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 3. PAGAR SALIDA
  Future<void> _pagarSalidaBackend() async {
    setState(() => isLoading = true);

    try {
      final response = await _supabase.rpc('pagar_salida',
          params: {'driver_uuid': currentDriverId, 'costo': costoSalida});

      if (response['success'] == true) {
        String ticketId = response['ticket_id'];

        setState(() {
          qrDataSeguro = ticketId;
        });

        await _fetchSaldoReal(); // Actualiza saldo visualmente
        if (mounted) _mostrarQRInstitucional(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response['message'] ?? "Error en transacción"),
            backgroundColor: AppColors.alertRed,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildGovernmentHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserCard(), // Ahora muestra el nombre real
                  const SizedBox(height: 25),
                  _buildStatusIndicator(),
                  const SizedBox(height: 25),
                  _buildBalanceSection(),
                  const SizedBox(height: 40),
                  _buildNationalActionButton(context),
                  const SizedBox(height: 20),
                  const Center(
                      child: Text("Sistema Automatizado de Transporte V1.0",
                          style: TextStyle(color: Colors.grey, fontSize: 10))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("TerminalSmart Charallave",
          style: TextStyle(fontSize: 16)),
      centerTitle: true,
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.security, color: AppColors.accentYellow),
          tooltip: "Modo Fiscal",
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ValidatorScreen()));
          },
        )
      ],
    );
  }

  Widget _buildGovernmentHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text("GOBIERNO MUNICIPAL",
              style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("TERMINAL CHARALLAVE",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            height: 4,
            width: 60,
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFC107),
                  Color(0xFF003875),
                  Color(0xFFD32F2F),
                ]),
                borderRadius: BorderRadius.circular(2)),
          )
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: AppColors.primaryBlue, size: 30),
        ),
        const SizedBox(width: 15),
        Expanded(
          // Expanded para evitar overflow si el nombre es muy largo
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Conductor Autorizado",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              // AQUI MOSTRAMOS LA VARIABLE DEL NOMBRE REAL
              Text(nombreConductor.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3))),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.satellite_alt, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Text("GPS ACTIVO • EN LINEA",
              style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TASA DE SALIDA (LISTÍN)",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey)),
                IconButton(
                  icon: Icon(
                      isBalanceVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.primaryBlue),
                  onPressed: () =>
                      setState(() => isBalanceVisible = !isBalanceVisible),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              isBalanceVisible ? "Bs. ${saldo.toStringAsFixed(2)}" : "********",
              style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: (saldo < costoSalida && isBalanceVisible)
                      ? AppColors.alertRed
                      : AppColors.primaryBlue,
                  letterSpacing: -1),
            ),
            const Text("Saldo Disponible (Nube)",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNationalActionButton(BuildContext context) {
    bool enabled = saldo >= costoSalida;
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: enabled ? () => _pagarSalidaBackend() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentYellow,
          foregroundColor: AppColors.primaryBlue,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 28),
            const SizedBox(width: 10),
            Text(
              enabled ? "PAGAR Y GENERAR PASE" : "SALDO INSUFICIENTE",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarQRInstitucional(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(
                      height: 5,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Color(0xFFFFC107),
                        Color(0xFF003875),
                        Color(0xFFD32F2F)
                      ]))),
                  const SizedBox(height: 20),
                  Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Flag_of_Venezuela.svg/2560px-Flag_of_Venezuela.svg.png",
                      height: 30,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.flag, color: Colors.yellow)),
                  const SizedBox(height: 10),
                  const Text(" PASE DE SALIDA AUTORIZADO ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 20),
                  QrImageView(
                      data: qrDataSeguro ?? "ERROR-NO-TICKET", size: 250),
                  const SizedBox(height: 10),
                  Text("Ticket ID: ${qrDataSeguro ?? '---'}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cerrar")),
                  )
                ],
              ),
            ));
  }
}
