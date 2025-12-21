// lib/ui/screens/validator_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import 'login_screen.dart';

class ValidatorScreen extends StatefulWidget {
  const ValidatorScreen({super.key});

  @override
  State<ValidatorScreen> createState() => _ValidatorScreenState();
}

class _ValidatorScreenState extends State<ValidatorScreen> {
  // CONFIGURACIÓN DE ESCÁNER
  final MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  // VALORES POR DEFECTO FORMULARIO
  String defaultDestination = "Caracas";
  int defaultPassengers = 32;
  String defaultObservation = "Sin Novedad";

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CONTROL DE PISTA"),
        backgroundColor: Colors.black, // Color de autoridad
        foregroundColor: Colors.white,
        actions: [
          // BOTÓN CERRAR TURNO
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Turno",
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. CÁMARA
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!isScanning) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // DETECTADO: Validamos y abrimos planilla
                  _validarYAbrirPlanilla(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. OVERLAY VISUAL
          _buildScannerOverlay(),

          // 3. MENSAJE FLOTANTE
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15)),
              child: const Text(
                "Escanee el QR del Conductor para abrir la Planilla de Despacho",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO ---

  // PASO 1: Verificar si el ticket existe y es válido antes de mostrar el formulario
  Future<void> _validarYAbrirPlanilla(String ticketId) async {
    setState(() => isScanning = false); // Pausamos cámara

    // Mostrar carga rápida
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final supabase = Supabase.instance.client;

      // Consultamos estatus y datos del chofer
      final data = await supabase
          .from('tickets')
          .select('status, profiles(full_name, placa, linea_transporte)')
          .eq('id', ticketId)
          .single();

      Navigator.pop(context); // Quitamos spinner

      final status = data['status'];
      final perfil = data['profiles'] as Map<String, dynamic>; // Datos unidos

      // VALIDACIÓN: Si ya se usó, no dejamos llenar planilla
      if (status == 'USADO') {
        _mostrarAlertaError(
            "Este ticket YA FUE PROCESADO.\nPlaca: ${perfil['placa']}");
        return;
      }

      // SI TODO OK: Abrimos la planilla digital
      if (mounted) {
        _mostrarPlanillaFiscal(ticketId, perfil);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Quitamos spinner si hay error
      _mostrarAlertaError("Código QR inválido o error de conexión.");
    }
  }

  // PASO 2: La "Hoja de Control" Digital (Modal)
  void _mostrarPlanillaFiscal(
      String ticketId, Map<String, dynamic> choferData) {
    // Variables locales temporales para el modal
    String destinoActual = defaultDestination;
    int pasajerosActual = defaultPassengers;
    String observacionActual = defaultObservation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        // StatefulBuilder permite actualizar la UI DENTRO del modal (slider, chips)
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
            height:
                MediaQuery.of(context).size.height * 0.90, // Alto casi completo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de agarre
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),

                // CABECERA: DATOS DEL CHOFER
                Row(
                  children: [
                    const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TICKET VÁLIDO",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                          Text("${choferData['placa']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 22)),
                          Text("${choferData['full_name']}",
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    // Etiqueta de la Línea
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(choferData['linea_transporte'] ?? "Privado",
                          style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Divider(thickness: 1, height: 30),

                // SECCIÓN 1: DESTINO
                const Text("📍 DESTINO DE LA UNIDAD",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    "Caracas",
                    "Cúa",
                    "Ocumare",
                    "Sta Teresa",
                    "Charallave Sur",
                    "Habilitado"
                  ].map((destino) {
                    final isSelected = destinoActual == destino;
                    return ChoiceChip(
                      label: Text(destino),
                      selected: isSelected,
                      selectedColor: AppColors.accentYellow,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal),
                      onSelected: (val) {
                        setModalState(() => destinoActual = destino);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),

                // SECCIÓN 2: PASAJEROS
                const Text("👥 CANTIDAD PASAJEROS",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                              onPressed: () => setModalState(() =>
                                  pasajerosActual > 0 ? pasajerosActual-- : 0),
                              icon: const Icon(Icons.remove)),
                          const SizedBox(width: 20),
                          Text("$pasajerosActual",
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87)),
                          const SizedBox(width: 20),
                          IconButton.filledTonal(
                              onPressed: () =>
                                  setModalState(() => pasajerosActual++),
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                      Slider(
                        value: pasajerosActual.toDouble(),
                        min: 0,
                        max: 60,
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) =>
                            setModalState(() => pasajerosActual = val.toInt()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECCIÓN 3: NOVEDADES
                const Text("⚠️ OBSERVACIONES",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: observacionActual,
                      isExpanded: true,
                      items: [
                        "Sin Novedad",
                        "Sin Uniforme",
                        "Vidrio Ahumado",
                        "Exceso Pasajeros",
                        "Neumáticos Lisos",
                        "Música Alta"
                      ]
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => observacionActual = val!),
                    ),
                  ),
                ),

                const Spacer(),

                // BOTÓN FINAL
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 5),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("REGISTRAR SALIDA Y CERRAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () async {
                      // Guardar en la Nube
                      await _guardarDatosEnNube(ticketId, destinoActual,
                          pasajerosActual, observacionActual);
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    ).whenComplete(() {
      // Al cerrar el modal (sea por guardar o cancelar), reactivamos cámara
      setState(() => isScanning = true);
    });
  }

  // PASO 3: Ejecutar la transacción en Supabase
  Future<void> _guardarDatosEnNube(
      String id, String dest, int pax, String obs) async {
    try {
      // Llamamos a la función SQL que crea el registro histórico y quema el ticket
      await Supabase.instance.client.rpc('registrar_salida_fiscal', params: {
        'p_ticket_id': id,
        'p_destination': dest,
        'p_passenger_count': pax,
        'p_observation': obs
      });

      // Cerrar Modal
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ Despacho Registrado Exitosamente"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Cerrar modal para ver error
      _mostrarAlertaError("Error al guardar: $e");
    }
  }

  // UTILS
  void _mostrarAlertaError(String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
                title: const Row(children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 10),
                  Text("ALERTA")
                ]),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Pequeña pausa antes de reactivar cámara
                        Future.delayed(const Duration(seconds: 1),
                            () => setState(() => isScanning = true));
                      },
                      child: const Text("ENTENDIDO"))
                ]));
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: const ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: AppColors.accentYellow,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }
}

// --- CLASE DEL MARCO VISUAL (Overlay) ---
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..addRect(Rect.fromCenter(
          center: rect.center, width: cutOutSize, height: cutOutSize));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
        center: rect.center, width: cutOutSize, height: cutOutSize);
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Fondo oscuro con hueco
    canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect)
          ..addRect(cutOutRect),
        backgroundPaint);
    // Borde cuadrado
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.center,
            width: cutOutSize + borderWidth,
            height: cutOutSize + borderWidth),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor);
}
