import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/detalle_evento_page.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_search_header.dart';
import 'package:escomevents_app/features/eventos/views/widgets/filtros_eventos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla de lista de eventos públicos para estudiantes.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  // Estado de los filtros (solo próximos/pasados, categoría y orden).
  FiltrosEventosUI _filtros = const FiltrosEventosUI(
    estado: FiltroEstado.proximos,
    orden: OrdenEvento.masProximos,
  );

  // Controlador de scroll para detectar cuando se llega al final.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Carga los eventos al iniciar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventos();
    });

    // Escucha el scroll para cargar más eventos.
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
      ref.read(eventosPublicosProvider.notifier).cargarMasEventos();
    }
  }

  // Carga los eventos públicos.
  Future<void> _cargarEventos() async {
    await ref.read(eventosPublicosProvider.notifier).cargarEventos(
          filtros: _filtros.toFiltroEventos(),
        );
  }

  // Aplica los filtros y recarga los eventos.
  void _aplicarFiltros(FiltrosEventosUI nuevosFiltros) {
    setState(() => _filtros = nuevosFiltros);
    ref.read(eventosPublicosProvider.notifier).cargarEventos(
          filtros: nuevosFiltros.toFiltroEventos(),
        );
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    ModalFiltrosEventos.mostrar(
      context: context,
      filtrosActuales: _filtros,
      mostrarFiltrosAvanzados: false, // Sin filtros avanzados para estudiantes.
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
          rol: ref.read(perfilActualProvider)?.rol ?? RolUsuario.estudiante,
          origen: OrigenDetalle.eventos,
          nombreOrganizador: nombreOrganizador,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estadoEventos = ref.watch(eventosPublicosProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header con búsqueda y filtros.
            EventSearchHeader(
              onFilterTap: _mostrarFiltros,
            ),

            // Chips de filtro rápido (solo Próximos y Pasados).
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
    );
  }

  // Construye el contenido según el estado de los eventos.
  Widget _construirContenido(
    EventosPublicosState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      EventosPublicosInicial() => _construirEstadoCargando(isDark),
      EventosPublicosCargando() => _construirEstadoCargando(isDark),
      EventosPublicosError(
        mensaje: final mensaje,
        eventosAnteriores: final eventosAnteriores
      ) =>
        eventosAnteriores.isNotEmpty
            ? _construirListaEventos(eventosAnteriores, theme, isDark)
            : _construirEstadoError(mensaje, theme, isDark),
      EventosPublicosExitoso(
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
          // Último item: indicador de carga o espacio.
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
            'No hay eventos ${obtenerNombreFiltroEstado(_filtros.estado).toLowerCase()}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
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
        return 'Próximos Eventos';
      case FiltroEstado.pasados:
        return 'Eventos Pasados';
      case FiltroEstado.todos:
      case FiltroEstado.pendientes:
      case FiltroEstado.enCorreccion:
      case FiltroEstado.aprobados:
        return 'Eventos';
    }
  }
}
