import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:flutter/material.dart';

// Tipos de filtro disponibles para "Mis Eventos".
enum FiltroMisEventos {
  proximos,
  pasados,
  pendientes,
  aprobados,
}

// Página para que los organizadores vean sus eventos.
//
// Incluye filtros para visualizar eventos según su estado y un
// botón flotante para crear nuevos eventos.
class MisEventosPage extends StatefulWidget {
  // Rol del usuario actual para determinar filtros visibles.
  final RolUsuario rol;

  const MisEventosPage({
    super.key,
    this.rol = RolUsuario.organizador,
  });

  @override
  State<MisEventosPage> createState() => _MisEventosPageState();
}

class _MisEventosPageState extends State<MisEventosPage> {
  FiltroMisEventos _filtroActual = FiltroMisEventos.proximos;

  // Obtiene los filtros disponibles según el rol del usuario.
  List<FiltroMisEventos> _obtenerFiltrosDisponibles() {
    final filtrosBase = <FiltroMisEventos>[
      FiltroMisEventos.proximos,
      FiltroMisEventos.pasados,
    ];

    // Pendientes y Aprobados solo para organizadores y administradores.
    if (widget.rol == RolUsuario.organizador ||
        widget.rol == RolUsuario.administrador) {
      filtrosBase.addAll([
        FiltroMisEventos.pendientes,
        FiltroMisEventos.aprobados,
      ]);
    }

    return filtrosBase;
  }

  // Obtiene el nombre legible del filtro.
  String _obtenerNombreFiltro(FiltroMisEventos filtro) {
    switch (filtro) {
      case FiltroMisEventos.proximos:
        return 'Próximos';
      case FiltroMisEventos.pasados:
        return 'Pasados';
      case FiltroMisEventos.pendientes:
        return 'Pendientes';
      case FiltroMisEventos.aprobados:
        return 'Aprobados';
    }
  }

  // Obtiene el icono del filtro.
  IconData _obtenerIconoFiltro(FiltroMisEventos filtro) {
    switch (filtro) {
      case FiltroMisEventos.proximos:
        return Icons.upcoming_outlined;
      case FiltroMisEventos.pasados:
        return Icons.history;
      case FiltroMisEventos.pendientes:
        return Icons.pending_actions;
      case FiltroMisEventos.aprobados:
        return Icons.check_circle_outline;
    }
  }

  // Filtra los eventos según el filtro seleccionado.
  List<EventModel> _filtrarEventos(List<EventModel> eventos) {
    final ahora = DateTime.now();

    switch (_filtroActual) {
      case FiltroMisEventos.proximos:
        return eventos
            .where((e) => e.fecha.isAfter(ahora) && e.validado)
            .toList();
      case FiltroMisEventos.pasados:
        return eventos
            .where((e) => e.fecha.isBefore(ahora) && e.validado)
            .toList();
      case FiltroMisEventos.pendientes:
        return eventos.where((e) => !e.validado).toList();
      case FiltroMisEventos.aprobados:
        return eventos.where((e) => e.validado).toList();
    }
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtrosDisponibles = _obtenerFiltrosDisponibles();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Filtrar eventos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...filtrosDisponibles.map((filtro) {
                final seleccionado = filtro == _filtroActual;
                return ListTile(
                  leading: Icon(
                    _obtenerIconoFiltro(filtro),
                    color: seleccionado
                        ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                        : Colors.grey,
                  ),
                  title: Text(
                    _obtenerNombreFiltro(filtro),
                    style: TextStyle(
                      fontWeight:
                          seleccionado ? FontWeight.bold : FontWeight.normal,
                      color: seleccionado
                          ? (isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary)
                          : null,
                    ),
                  ),
                  trailing: seleccionado
                      ? Icon(
                          Icons.check,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _filtroActual = filtro);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Muestra el formulario para crear un nuevo evento.
  void _mostrarFormularioNuevoEvento() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                  // TODO: Implementar formulario de creación de evento.
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.construction,
                            size: 64,
                            color: isDark
                                ? AppColors.darkSecondary
                                : AppColors.lightSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Formulario en construcción',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Próximamente podrás crear eventos aquí',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
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

    // Datos de prueba para el diseño.
    // TODO: Conectar con el repositorio de eventos.
    final List<EventModel> eventosMock = [
      EventModel(
        id: 1,
        idOrganizador: 'org1',
        nombre: 'Hackathon 2026: Innovación AI',
        fecha: DateTime(2026, 1, 6, 9, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: 'Auditorio A',
        imageUrl:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80',
      ),
      EventModel(
        id: 2,
        idOrganizador: 'org1',
        nombre: 'Taller de Flutter Avanzado',
        fecha: DateTime(2026, 1, 7, 14, 30),
        fechaCreacion: DateTime.now(),
        entradaLibre: false,
        validado: false,
        categorias: [],
        lugar: 'Lab de Cómputo 3',
        imageUrl:
            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80',
      ),
      EventModel(
        id: 3,
        idOrganizador: 'org1',
        nombre: 'Torneo de Fútbol Inter-ESCOM',
        fecha: DateTime(2024, 12, 15, 12, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: 'Canchas Deportivas',
        imageUrl:
            'https://images.unsplash.com/photo-1579952363873-27f3bade8f55?auto=format&fit=crop&w=800&q=80',
      ),
    ];

    final eventosFiltrados = _filtrarEventos(eventosMock);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header con título y botón de filtros.
            _construirHeader(theme, isDark),

            // Chips de filtro activo.
            _construirChipsFiltro(theme, isDark),

            // Lista de eventos.
            Expanded(
              child: eventosFiltrados.isEmpty
                  ? _construirEstadoVacio(theme, isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: eventosFiltrados.length,
                      itemBuilder: (context, index) {
                        return EventCard(
                          event: eventosFiltrados[index],
                          onTap: () {
                            // TODO: Navegación al detalle del evento.
                          },
                        );
                      },
                    ),
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

  // Construye los chips de filtro activo.
  Widget _construirChipsFiltro(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _obtenerFiltrosDisponibles().map((filtro) {
            final seleccionado = filtro == _filtroActual;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: seleccionado,
                label: Text(_obtenerNombreFiltro(filtro)),
                avatar: Icon(
                  _obtenerIconoFiltro(filtro),
                  size: 18,
                  color: seleccionado
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary),
                ),
                selectedColor:
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: seleccionado
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary),
                  fontWeight:
                      seleccionado ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                onSelected: (selected) {
                  setState(() => _filtroActual = filtro);
                },
              ),
            );
          }).toList(),
        ),
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
            'No tienes eventos ${_obtenerNombreFiltro(_filtroActual).toLowerCase()}',
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
