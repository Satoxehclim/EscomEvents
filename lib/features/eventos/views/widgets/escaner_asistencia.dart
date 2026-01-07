import 'dart:convert';

import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/eventos/viewmodel/asistencia_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Pantalla del escáner de asistencia para organizadores.
class EscanerAsistenciaPage extends ConsumerStatefulWidget {
  final int idEvento;
  final String nombreEvento;

  const EscanerAsistenciaPage({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
  });

  @override
  ConsumerState<EscanerAsistenciaPage> createState() =>
      _EscanerAsistenciaPageState();
}

class _EscanerAsistenciaPageState extends ConsumerState<EscanerAsistenciaPage>
    with WidgetsBindingObserver {
  // Controlador del escáner (se inicializa en initState).
  late final MobileScannerController _controladorEscaner;

  // Set para evitar escanear el mismo QR múltiples veces.
  final Set<String> _qrEscaneados = {};

  // Estado de procesamiento.
  bool _procesando = false;

  // Lista de resultados del escaneo.
  final List<_ResultadoEscaneo> _resultados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controladorEscaner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausa la cámara cuando la app está en segundo plano.
    if (!_controladorEscaner.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controladorEscaner.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controladorEscaner.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controladorEscaner.dispose();
    super.dispose();
  }

  // Procesa el código QR escaneado.
  Future<void> _procesarQr(String codigoQr) async {
    // Evita procesar si ya está procesando o si ya se escaneó.
    if (_procesando || _qrEscaneados.contains(codigoQr)) {
      return;
    }

    setState(() {
      _procesando = true;
      _qrEscaneados.add(codigoQr);
    });

    try {
      // Parsea el JSON del QR.
      final datosQr = jsonDecode(codigoQr) as Map<String, dynamic>;

      // Valida que sea un QR de estudiante.
      if (datosQr['tipo'] != 'estudiante') {
        _agregarResultado(
          tipo: TipoResultado.error,
          mensaje: 'QR no válido: no es un código de estudiante',
        );
        return;
      }

      final idPerfil = datosQr['idPerfil'] as String?;
      final nombreEstudiante = datosQr['nombre'] as String? ?? 'Desconocido';

      if (idPerfil == null) {
        _agregarResultado(
          tipo: TipoResultado.error,
          mensaje: 'QR inválido: falta información del estudiante',
        );
        return;
      }

      // Marca la asistencia.
      final resultado =
          await ref.read(escaneoAsistenciaProvider.notifier).marcarAsistencia(
                idPerfil: idPerfil,
                nombreEstudiante: nombreEstudiante,
                idEvento: widget.idEvento,
              );

      // Procesa el resultado.
      switch (resultado) {
        case EscaneoExitoso(nombreEstudiante: final nombre):
          _agregarResultado(
            tipo: TipoResultado.exito,
            mensaje: '¡Asistencia registrada!',
            nombreEstudiante: nombre,
          );
          break;
        case EscaneoYaRegistrado(nombreEstudiante: final nombre):
          _agregarResultado(
            tipo: TipoResultado.yaRegistrado,
            mensaje: 'Asistencia ya registrada',
            nombreEstudiante: nombre,
          );
          break;
        case EscaneoNoRegistrado():
          _agregarResultado(
            tipo: TipoResultado.error,
            mensaje: 'El estudiante no está inscrito al evento',
          );
          break;
        case EscaneoError(mensaje: final msg):
          _agregarResultado(
            tipo: TipoResultado.error,
            mensaje: msg,
          );
          break;
      }
    } on FormatException {
      _agregarResultado(
        tipo: TipoResultado.error,
        mensaje: 'QR inválido: formato no reconocido',
      );
    } catch (e) {
      _agregarResultado(
        tipo: TipoResultado.error,
        mensaje: 'Error al procesar QR: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  // Agrega un resultado a la lista.
  void _agregarResultado({
    required TipoResultado tipo,
    required String mensaje,
    String? nombreEstudiante,
  }) {
    if (!mounted) return;

    setState(() {
      _resultados.insert(
        0,
        _ResultadoEscaneo(
          tipo: tipo,
          mensaje: mensaje,
          nombreEstudiante: nombreEstudiante,
          hora: DateTime.now(),
        ),
      );

      // Limita a 10 resultados.
      // if (_resultados.length > 10) {
      //   _resultados.removeLast();
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pasar Asistencia'),
            Text(
              widget.nombreEvento,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        actions: [
          // Botón para alternar flash.
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controladorEscaner,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controladorEscaner.toggleTorch(),
          ),
          // Botón para cambiar cámara.
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controladorEscaner.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Área del escáner.
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Escáner.
                MobileScanner(
                  controller: _controladorEscaner,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _procesarQr(barcode.rawValue!);
                      }
                    }
                  },
                ),

                // Overlay con guía de escaneo.
                _construirOverlay(isDark),

                // Indicador de procesamiento.
                if (_procesando)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de resultados.
          Expanded(
            flex: 2,
            child: Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Historial de escaneos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_resultados.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _resultados.clear();
                                _qrEscaneados.clear();
                              });
                            },
                            child: const Text('Limpiar'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _resultados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Escanea el QR de un estudiante',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _resultados.length,
                            itemBuilder: (context, index) {
                              return _TarjetaResultado(
                                resultado: _resultados[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el overlay de guía.
  Widget _construirOverlay(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tamanoRecuadro = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - tamanoRecuadro) / 2;
        final top = (constraints.maxHeight - tamanoRecuadro) / 2;

        return Stack(
          children: [
            // Fondo oscuro con recorte.
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: tamanoRecuadro,
                      height: tamanoRecuadro,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Borde del recuadro.
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: tamanoRecuadro,
                height: tamanoRecuadro,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Instrucción.
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Apunta al código QR del estudiante',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Tipo de resultado del escaneo.
enum TipoResultado {
  exito,
  yaRegistrado,
  error,
}

// Modelo de resultado de escaneo.
class _ResultadoEscaneo {
  final TipoResultado tipo;
  final String mensaje;
  final String? nombreEstudiante;
  final DateTime hora;

  const _ResultadoEscaneo({
    required this.tipo,
    required this.mensaje,
    this.nombreEstudiante,
    required this.hora,
  });
}

// Tarjeta que muestra un resultado de escaneo.
class _TarjetaResultado extends StatelessWidget {
  final _ResultadoEscaneo resultado;

  const _TarjetaResultado({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, icono) = switch (resultado.tipo) {
      TipoResultado.exito => (Colors.green, Icons.check_circle),
      TipoResultado.yaRegistrado => (Colors.orange, Icons.info),
      TipoResultado.error => (Colors.red, Icons.error),
    };

    final horaFormateada =
        '${resultado.hora.hour.toString().padLeft(2, '0')}:${resultado.hora.minute.toString().padLeft(2, '0')}:${resultado.hora.second.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icono, color: color),
        ),
        title: Text(
          resultado.nombreEstudiante ?? resultado.mensaje,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: resultado.nombreEstudiante != null
            ? Text(resultado.mensaje)
            : null,
        trailing: Text(
          horaFormateada,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
