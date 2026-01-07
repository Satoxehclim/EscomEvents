import 'dart:convert';

import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/detalle_evento_page.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/filtros_eventos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Pantalla de eventos a los que el estudiante asistirá.
class MisEventosEstudiantePage extends ConsumerStatefulWidget {
  const MisEventosEstudiantePage({super.key});

  @override
  ConsumerState<MisEventosEstudiantePage> createState() =>
      _MisEventosEstudiantePageState();
}

class _MisEventosEstudiantePageState
    extends ConsumerState<MisEventosEstudiantePage> {
  // Estado de los filtros.
  FiltrosEventosUI _filtros = const FiltrosEventosUI(
    estado: FiltroEstado.proximos,
    orden: OrdenEvento.masProximos,
  );

  // Controlador de scroll para paginación.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventos();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Detecta cuando se acerca al final de la lista.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(eventosEstudianteProvider.notifier).cargarMasEventos();
    }
  }

  // Carga los eventos con asistencia.
  Future<void> _cargarEventos() async {
    final perfil = ref.read(perfilActualProvider);
    if (perfil != null) {
      await ref.read(eventosEstudianteProvider.notifier).cargarEventos(
            perfil.idPerfil,
            filtros: _filtros.toFiltroEventos(),
          );
    }
  }

  // Aplica los filtros y recarga los eventos.
  void _aplicarFiltros(FiltrosEventosUI nuevosFiltros) {
    setState(() => _filtros = nuevosFiltros);
    final perfil = ref.read(perfilActualProvider);
    if (perfil != null) {
      ref.read(eventosEstudianteProvider.notifier).cargarEventos(
            perfil.idPerfil,
            filtros: nuevosFiltros.toFiltroEventos(),
          );
    }
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    ModalFiltrosEventos.mostrar(
      context: context,
      filtrosActuales: _filtros,
      mostrarFiltrosAvanzados: false,
      onAplicar: _aplicarFiltros,
    );
  }

  // Muestra el QR del estudiante.
  void _mostrarQr() {
    final perfil = ref.read(perfilActualProvider);
    if (perfil == null) return;

    // Estructura de datos del QR.
    final datosQr = jsonEncode({
      'tipo': 'estudiante',
      'idPerfil': perfil.idPerfil,
      'nombre': perfil.nombre,
      'timestamp': DateTime.now().toIso8601String(),
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DialogoQrEstudiante(
        datosQr: datosQr,
        nombreEstudiante: perfil.nombre,
      ),
    );
  }

  // Navega a la página de detalle del evento.
  Future<void> _navegarADetalle(EventModel evento) async {
    final perfil = ref.read(perfilActualProvider);
    if (perfil == null) return;

    final repository = ref.read(eventoRepositoryProvider);
    final nombreOrganizador =
        await repository.obtenerNombreOrganizador(evento.idOrganizador);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEventoPage(
          evento: evento,
          rol: perfil.rol,
          origen: OrigenDetalle.misEventosEstudiante,
          nombreOrganizador: nombreOrganizador,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estadoEventos = ref.watch(eventosEstudianteProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header.
            _construirHeader(theme, isDark),

            // Chips de filtro rápido.
            ChipsFiltroEstado(
              filtroSeleccionado: _filtros.estado,
              mostrarFiltrosAvanzados: false,
              onSeleccionar: (filtro) {
                _aplicarFiltros(_filtros.copyWith(estado: filtro));
              },
            ),

            // Título de sección.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _obtenerTituloSeccion(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Contenido según el estado.
            Expanded(
              child: _construirContenido(estadoEventos, theme, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarQr,
        icon: const Icon(Icons.qr_code),
        label: const Text('Mi QR'),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Construye el header.
  Widget _construirHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mis Eventos',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _mostrarFiltros,
            ),
          ),
        ],
      ),
    );
  }

  // Construye el contenido según el estado.
  Widget _construirContenido(
    EventosEstudianteState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      EventosEstudianteInicial() => _construirEstadoCargando(isDark),
      EventosEstudianteCargando() => _construirEstadoCargando(isDark),
      EventosEstudianteError(
        mensaje: final mensaje,
        eventosAnteriores: final eventosAnteriores
      ) =>
        eventosAnteriores.isNotEmpty
            ? _construirListaEventos(eventosAnteriores, theme, isDark)
            : _construirEstadoError(mensaje, theme, isDark),
      EventosEstudianteExitoso(
        eventos: final eventos,
        hayMas: final hayMas,
        cargandoMas: final cargandoMas
      ) =>
        _construirListaEventos(
          eventos,
          theme,
          isDark,
          hayMas: hayMas,
          cargandoMas: cargandoMas,
        ),
    };
  }

  // Construye el estado de carga.
  Widget _construirEstadoCargando(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
    );
  }

  // Construye el estado de error.
  Widget _construirEstadoError(String mensaje, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar eventos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarEventos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye la lista de eventos.
  Widget _construirListaEventos(
    List<EventModel> eventos,
    ThemeData theme,
    bool isDark, {
    bool hayMas = false,
    bool cargandoMas = false,
  }) {
    if (eventos.isEmpty) {
      return _construirEstadoVacio(theme, isDark);
    }

    final itemCount = eventos.length + (cargandoMas || hayMas ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _cargarEventos,
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == eventos.length) {
            if (cargandoMas) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            return const SizedBox(height: 16);
          }

          return EventCard(
            event: eventos[index],
            onTap: () => _navegarADetalle(eventos[index]),
          );
        },
      ),
    );
  }

  // Construye el estado vacío.
  Widget _construirEstadoVacio(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes eventos registrados',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora eventos y marca "Asistiré"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Obtiene el título de la sección según el filtro.
  String _obtenerTituloSeccion() {
    switch (_filtros.estado) {
      case FiltroEstado.proximos:
        return 'Próximos';
      case FiltroEstado.pasados:
        return 'Pasados';
      case FiltroEstado.todos:
      case FiltroEstado.pendientes:
      case FiltroEstado.enCorreccion:
      case FiltroEstado.aprobados:
        return 'Eventos';
    }
  }
}

// Diálogo que muestra el QR del estudiante.
class _DialogoQrEstudiante extends StatelessWidget {
  final String datosQr;
  final String nombreEstudiante;

  const _DialogoQrEstudiante({
    required this.datosQr,
    required this.nombreEstudiante,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrastre.
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título.
          Text(
            'Mi Código QR',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombreEstudiante,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // QR Code.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: datosQr,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 24),

          // Instrucciones.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimary.withValues(alpha: 0.1)
                  : AppColors.lightPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Muestra este código al organizador del evento para registrar tu asistencia.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
