import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/detalle_evento_page.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/filtros_eventos.dart';
import 'package:escomevents_app/features/eventos/views/widgets/formulario_nuevo_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Página para que los organizadores vean sus eventos.
//
// Incluye filtros para visualizar eventos según su estado y un
// botón flotante para crear nuevos eventos.
class MisEventosPage extends ConsumerStatefulWidget {
  // Rol del usuario actual para determinar filtros visibles.
  final RolUsuario rol;

  const MisEventosPage({
    super.key,
    this.rol = RolUsuario.organizador,
  });

  @override
  ConsumerState<MisEventosPage> createState() => _MisEventosPageState();
}

class _MisEventosPageState extends ConsumerState<MisEventosPage> {
  // Estado de los filtros.
  FiltrosEventosUI _filtros = const FiltrosEventosUI();

  // Controlador de scroll para detectar cuando se llega al final.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Carga los eventos del organizador al iniciar.
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
      // Carga más eventos si está cerca del final.
      ref.read(eventosOrganizadorProvider.notifier).cargarMasEventos();
    }
  }

  // Carga los eventos del organizador desde la base de datos.
  Future<void> _cargarEventos() async {
    final perfil = ref.read(perfilActualProvider);
    if (perfil != null) {
      await ref.read(eventosOrganizadorProvider.notifier).cargarEventos(
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
      ref.read(eventosOrganizadorProvider.notifier).cargarEventos(
            perfil.idPerfil,
            filtros: nuevosFiltros.toFiltroEventos(),
          );
    }
  }

  // Determina si se muestran filtros avanzados según el rol.
  bool get _mostrarFiltrosAvanzados =>
      widget.rol == RolUsuario.organizador ||
      widget.rol == RolUsuario.administrador;

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    ModalFiltrosEventos.mostrar(
      context: context,
      filtrosActuales: _filtros,
      mostrarFiltrosAvanzados: _mostrarFiltrosAvanzados,
      onAplicar: _aplicarFiltros,
    );
  }

  // Navega a la página de detalle del evento.
  Future<void> _navegarADetalle(EventModel evento) async {
    // Obtiene el nombre del organizador.
    final repository = ref.read(eventoRepositoryProvider);
    final nombreOrganizador =
        await repository.obtenerNombreOrganizador(evento.idOrganizador);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEventoPage(
          evento: evento,
          rol: widget.rol,
          origen: OrigenDetalle.misEventos,
          nombreOrganizador: nombreOrganizador,
          onEventoActualizado: (eventoActualizado) {
            // Actualiza el evento en la lista.
            ref
                .read(eventosOrganizadorProvider.notifier)
                .actualizarEvento(eventoActualizado);
          },
          onEventoEliminado: () {
            // Elimina el evento de la lista y de la base de datos.
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
      // Elimina de la lista local.
      ref.read(eventosOrganizadorProvider.notifier).eliminarEvento(evento.id);

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

  // Muestra el formulario para crear un nuevo evento.
  void _mostrarFormularioNuevoEvento() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nuevo Evento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Formulario de creación de evento.
                  Expanded(
                    child: FormularioNuevoEvento(
                      onGuardar: () => Navigator.pop(context),
                      onCancelar: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estadoEventos = ref.watch(eventosOrganizadorProvider);

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
              mostrarFiltrosAvanzados: _mostrarFiltrosAvanzados,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioNuevoEvento,
        backgroundColor:
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Evento'),
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
              'Mis Eventos',
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
    EventosOrganizadorState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      EventosOrganizadorInicial() => _construirEstadoCargando(isDark),
      EventosOrganizadorCargando() => _construirEstadoCargando(isDark),
      EventosOrganizadorError(
        mensaje: final mensaje,
        eventosAnteriores: final eventosAnteriores
      ) =>
        eventosAnteriores.isNotEmpty
            ? _construirListaEventos(eventosAnteriores, theme, isDark)
            : _construirEstadoError(mensaje, theme, isDark),
      EventosOrganizadorExitoso(
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

  // Construye la lista de eventos filtrados con paginación.
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

    // Calcula el número de items (eventos + indicador de carga si aplica).
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
            // Espacio para que el scroll funcione si hay más.
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

  // Construye el estado vacío cuando no hay eventos.
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
            'No tienes eventos ${obtenerNombreFiltroEstado(_filtros.estado).toLowerCase()}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón + para crear uno',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
