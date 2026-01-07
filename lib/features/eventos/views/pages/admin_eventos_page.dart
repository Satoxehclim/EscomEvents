import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/detalle_evento_page.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/filtros_eventos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Página para que los administradores gestionen eventos pendientes.
class AdminEventosPage extends ConsumerStatefulWidget {
  const AdminEventosPage({super.key});

  @override
  ConsumerState<AdminEventosPage> createState() => _AdminEventosPageState();
}

class _AdminEventosPageState extends ConsumerState<AdminEventosPage> {
  // Estado de los filtros (por defecto muestra pendientes).
  FiltrosEventosUI _filtros = const FiltrosEventosUI(
    estado: FiltroEstado.pendientes,
    orden: OrdenEvento.masRecientes,
  );

  // Controlador de scroll para detectar cuando se llega al final.
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
      ref.read(eventosAdminProvider.notifier).cargarMasEventos();
    }
  }

  // Carga los eventos para administración.
  Future<void> _cargarEventos() async {
    await ref.read(eventosAdminProvider.notifier).cargarEventos(
          filtros: _filtros.toFiltroEventos(),
        );
  }

  // Aplica los filtros y recarga los eventos.
  void _aplicarFiltros(FiltrosEventosUI nuevosFiltros) {
    setState(() => _filtros = nuevosFiltros);
    ref.read(eventosAdminProvider.notifier).cargarEventos(
          filtros: nuevosFiltros.toFiltroEventos(),
        );
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    ModalFiltrosEventos.mostrar(
      context: context,
      filtrosActuales: _filtros,
      mostrarFiltrosAvanzados: true, // Admin tiene todos los filtros.
      onAplicar: _aplicarFiltros,
    );
  }

  // Navega a la página de detalle del evento.
  Future<void> _navegarADetalle(EventModel evento) async {
    final repository = ref.read(eventoRepositoryProvider);
    final nombreOrganizador =
        await repository.obtenerNombreOrganizador(evento.idOrganizador);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEventoPage(
          evento: evento,
          rol: RolUsuario.administrador,
          origen: OrigenDetalle.misEventos,
          nombreOrganizador: nombreOrganizador,
          onEventoActualizado: (eventoActualizado) {
            ref
                .read(eventosAdminProvider.notifier)
                .actualizarEvento(eventoActualizado);
          },
          onEventoEliminado: () {
            _eliminarEvento(evento);
          },
        ),
      ),
    );
  }

  // Elimina un evento.
  Future<void> _eliminarEvento(EventModel evento) async {
    final exito =
        await ref.read(eliminarEventoProvider.notifier).eliminarEvento(evento);

    if (exito && mounted) {
      ref.read(eventosAdminProvider.notifier).eliminarEvento(evento.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      final estadoError = ref.read(eliminarEventoProvider);
      if (estadoError is EliminarEventoError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${estadoError.mensaje}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estadoEventos = ref.watch(eventosAdminProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header con título y botón de filtros.
            _construirHeader(theme, isDark),

            // Chips de filtro rápido.
            ChipsFiltroEstado(
              filtroSeleccionado: _filtros.estado,
              mostrarFiltrosAvanzados: true,
              onSeleccionar: (filtro) {
                _aplicarFiltros(_filtros.copyWith(estado: filtro));
              },
            ),

            // Contenido según el estado.
            Expanded(
              child: _construirContenido(estadoEventos, theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Construye el header con título y botón de filtros.
  Widget _construirHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Administrar Eventos',
              style: theme.textTheme.headlineSmall?.copyWith(
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

  // Construye el contenido según el estado de los eventos.
  Widget _construirContenido(
    EventosAdminState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      EventosAdminInicial() => _construirEstadoCargando(isDark),
      EventosAdminCargando() => _construirEstadoCargando(isDark),
      EventosAdminError(
        mensaje: final mensaje,
        eventosAnteriores: final eventosAnteriores
      ) =>
        eventosAnteriores.isNotEmpty
            ? _construirListaEventos(eventosAnteriores, theme, isDark)
            : _construirEstadoError(mensaje, theme, isDark),
      EventosAdminExitoso(
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

  // Construye la lista de eventos con paginación.
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
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay eventos ${obtenerNombreFiltroEstado(_filtros.estado).toLowerCase()}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (_filtros.estado == FiltroEstado.pendientes) ...[
            const SizedBox(height: 8),
            Text(
              '¡Todos los eventos han sido revisados!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
