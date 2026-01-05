import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_dropdown.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:flutter/material.dart';

// Tipos de filtro de estado para "Mis Eventos".
enum FiltroEstado {
  todos,
  proximos,
  pasados,
  pendientes,
  aprobados,
}

// Tipos de ordenamiento para "Mis Eventos".
enum OrdenarPor {
  masRecientes,
  masAntiguos,
  masProximos,
  masLejanos,
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
  // Estado de los filtros.
  OrdenarPor _ordenarPor = OrdenarPor.masRecientes;
  FiltroEstado _filtroEstado = FiltroEstado.todos;
  String? _categoriaSeleccionada;

  // Items para el dropdown de ordenamiento.
  List<DropdownItem<OrdenarPor>> _obtenerItemsOrdenamiento() {
    return const [
      DropdownItem(
        valor: OrdenarPor.masRecientes,
        etiqueta: 'Más recientes',
        icono: Icons.schedule,
      ),
      DropdownItem(
        valor: OrdenarPor.masAntiguos,
        etiqueta: 'Más antiguos',
        icono: Icons.history,
      ),
      DropdownItem(
        valor: OrdenarPor.masProximos,
        etiqueta: 'Más próximos',
        icono: Icons.event_available,
      ),
      DropdownItem(
        valor: OrdenarPor.masLejanos,
        etiqueta: 'Más lejanos',
        icono: Icons.event_note,
      ),
    ];
  }

  // Items para el dropdown de estado.
  List<DropdownItem<FiltroEstado>> _obtenerItemsEstado() {
    final itemsBase = <DropdownItem<FiltroEstado>>[
      const DropdownItem(
        valor: FiltroEstado.todos,
        etiqueta: 'Todos',
        icono: Icons.all_inclusive,
      ),
      const DropdownItem(
        valor: FiltroEstado.proximos,
        etiqueta: 'Próximos',
        icono: Icons.upcoming_outlined,
      ),
      const DropdownItem(
        valor: FiltroEstado.pasados,
        etiqueta: 'Pasados',
        icono: Icons.history,
      ),
    ];

    // Pendientes y Aprobados solo para organizadores y administradores.
    if (widget.rol == RolUsuario.organizador ||
        widget.rol == RolUsuario.administrador) {
      itemsBase.addAll(const [
        DropdownItem(
          valor: FiltroEstado.pendientes,
          etiqueta: 'Pendientes',
          icono: Icons.pending_actions,
        ),
        DropdownItem(
          valor: FiltroEstado.aprobados,
          etiqueta: 'Aprobados',
          icono: Icons.check_circle_outline,
        ),
      ]);
    }

    return itemsBase;
  }

  // TODO: Obtener categorías desde el repositorio.
  List<DropdownItem<String>> _obtenerItemsCategorias() {
    return const [
      // Placeholder - conectar con el repositorio de categorías.
    ];
  }

  // Obtiene el nombre legible del filtro de estado.
  String _obtenerNombreFiltroEstado(FiltroEstado filtro) {
    switch (filtro) {
      case FiltroEstado.todos:
        return 'Todos';
      case FiltroEstado.proximos:
        return 'Próximos';
      case FiltroEstado.pasados:
        return 'Pasados';
      case FiltroEstado.pendientes:
        return 'Pendientes';
      case FiltroEstado.aprobados:
        return 'Aprobados';
    }
  }

  // Obtiene el icono del filtro de estado.
  IconData _obtenerIconoFiltroEstado(FiltroEstado filtro) {
    switch (filtro) {
      case FiltroEstado.todos:
        return Icons.all_inclusive;
      case FiltroEstado.proximos:
        return Icons.upcoming_outlined;
      case FiltroEstado.pasados:
        return Icons.history;
      case FiltroEstado.pendientes:
        return Icons.pending_actions;
      case FiltroEstado.aprobados:
        return Icons.check_circle_outline;
    }
  }

  // Filtra y ordena los eventos.
  List<EventModel> _filtrarYOrdenarEventos(List<EventModel> eventos) {
    final ahora = DateTime.now();

    // Filtrar por estado.
    List<EventModel> eventosFiltrados;
    switch (_filtroEstado) {
      case FiltroEstado.todos:
        eventosFiltrados = List.from(eventos);
        break;
      case FiltroEstado.proximos:
        eventosFiltrados =
            eventos.where((e) => e.fecha.isAfter(ahora) && e.validado).toList();
        break;
      case FiltroEstado.pasados:
        eventosFiltrados = eventos
            .where((e) => e.fecha.isBefore(ahora) && e.validado)
            .toList();
        break;
      case FiltroEstado.pendientes:
        eventosFiltrados = eventos.where((e) => !e.validado).toList();
        break;
      case FiltroEstado.aprobados:
        eventosFiltrados = eventos.where((e) => e.validado).toList();
        break;
    }

    // TODO: Filtrar por categoría cuando se implemente.

    // Ordenar.
    switch (_ordenarPor) {
      case OrdenarPor.masRecientes:
        eventosFiltrados.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        break;
      case OrdenarPor.masAntiguos:
        eventosFiltrados.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        break;
      case OrdenarPor.masProximos:
        eventosFiltrados.sort((a, b) => a.fecha.compareTo(b.fecha));
        break;
      case OrdenarPor.masLejanos:
        eventosFiltrados.sort((a, b) => b.fecha.compareTo(a.fecha));
        break;
    }

    return eventosFiltrados;
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Variables temporales para el modal.
    OrdenarPor ordenarPorTemp = _ordenarPor;
    FiltroEstado filtroEstadoTemp = _filtroEstado;
    String? categoriaTemp = _categoriaSeleccionada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de arrastre.
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

                  // Título.
                  Text(
                    'Filtrar eventos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dropdown de ordenamiento.
                  CustomDropdown<OrdenarPor>(
                    etiqueta: 'Ordenar por',
                    textoHint: 'Selecciona un orden',
                    iconoPrefijo: Icons.sort,
                    valorSeleccionado: ordenarPorTemp,
                    elementos: _obtenerItemsOrdenamiento(),
                    onChanged: (valor) {
                      setModalState(() => ordenarPorTemp = valor!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown de estado.
                  CustomDropdown<FiltroEstado>(
                    etiqueta: 'Estado',
                    textoHint: 'Selecciona un estado',
                    iconoPrefijo: Icons.filter_alt_outlined,
                    valorSeleccionado: filtroEstadoTemp,
                    elementos: _obtenerItemsEstado(),
                    onChanged: (valor) {
                      setModalState(() => filtroEstadoTemp = valor!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown de categoría.
                  CustomDropdown<String>(
                    etiqueta: 'Categoría',
                    textoHint: 'Selecciona una categoría',
                    iconoPrefijo: Icons.category_outlined,
                    valorSeleccionado: categoriaTemp,
                    elementos: _obtenerItemsCategorias(),
                    onChanged: (valor) {
                      setModalState(() => categoriaTemp = valor);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción.
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          texto: 'Limpiar',
                          tipo: CustomButtonType.outlined,
                          onPressed: () {
                            setModalState(() {
                              ordenarPorTemp = OrdenarPor.masRecientes;
                              filtroEstadoTemp = FiltroEstado.todos;
                              categoriaTemp = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          texto: 'Aplicar',
                          tipo: CustomButtonType.primary,
                          onPressed: () {
                            setState(() {
                              _ordenarPor = ordenarPorTemp;
                              _filtroEstado = filtroEstadoTemp;
                              _categoriaSeleccionada = categoriaTemp;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
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

    final eventosFiltrados = _filtrarYOrdenarEventos(eventosMock);

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
    final itemsEstado = _obtenerItemsEstado();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: itemsEstado.map((item) {
            final seleccionado = item.valor == _filtroEstado;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: seleccionado,
                label: Text(item.etiqueta),
                avatar: Icon(
                  item.icono,
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
                  setState(() => _filtroEstado = item.valor);
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
            'No tienes eventos ${_obtenerNombreFiltroEstado(_filtroEstado).toLowerCase()}',
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
