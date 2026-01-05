import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_dropdown.dart';
import 'package:flutter/material.dart';

// Tipos de filtro de estado para eventos.
enum FiltroEstado {
  todos,
  proximos,
  pasados,
  pendientes,
  aprobados,
}

// Tipos de ordenamiento para eventos.
enum OrdenarPor {
  masRecientes,
  masAntiguos,
  masProximos,
  masLejanos,
}

// Modelo para almacenar el estado de los filtros.
class FiltrosEventos {
  final OrdenarPor ordenarPor;
  final FiltroEstado filtroEstado;
  final String? categoria;

  const FiltrosEventos({
    this.ordenarPor = OrdenarPor.masRecientes,
    this.filtroEstado = FiltroEstado.todos,
    this.categoria,
  });

  FiltrosEventos copyWith({
    OrdenarPor? ordenarPor,
    FiltroEstado? filtroEstado,
    String? categoria,
  }) {
    return FiltrosEventos(
      ordenarPor: ordenarPor ?? this.ordenarPor,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      categoria: categoria ?? this.categoria,
    );
  }

  // Limpia los filtros a valores por defecto.
  FiltrosEventos limpiar({FiltroEstado estadoPorDefecto = FiltroEstado.todos}) {
    return FiltrosEventos(
      ordenarPor: OrdenarPor.masRecientes,
      filtroEstado: estadoPorDefecto,
      categoria: null,
    );
  }
}

// Modal de filtros reutilizable para eventos.
//
// Puede mostrar diferentes opciones de estado según [mostrarFiltrosAvanzados].
class ModalFiltrosEventos extends StatefulWidget {
  // Filtros actuales.
  final FiltrosEventos filtrosActuales;

  // Si es true, muestra las opciones "Pendientes" y "Aprobados".
  final bool mostrarFiltrosAvanzados;

  // Callback cuando se aplican los filtros.
  final ValueChanged<FiltrosEventos> onAplicar;

  const ModalFiltrosEventos({
    super.key,
    required this.filtrosActuales,
    this.mostrarFiltrosAvanzados = false,
    required this.onAplicar,
  });

  @override
  State<ModalFiltrosEventos> createState() => _ModalFiltrosEventosState();

  // Muestra el modal de filtros.
  static void mostrar({
    required BuildContext context,
    required FiltrosEventos filtrosActuales,
    bool mostrarFiltrosAvanzados = false,
    required ValueChanged<FiltrosEventos> onAplicar,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ModalFiltrosEventos(
          filtrosActuales: filtrosActuales,
          mostrarFiltrosAvanzados: mostrarFiltrosAvanzados,
          onAplicar: onAplicar,
        );
      },
    );
  }
}

class _ModalFiltrosEventosState extends State<ModalFiltrosEventos> {
  late OrdenarPor _ordenarPor;
  late FiltroEstado _filtroEstado;
  late String? _categoria;

  @override
  void initState() {
    super.initState();
    _ordenarPor = widget.filtrosActuales.ordenarPor;
    _filtroEstado = widget.filtrosActuales.filtroEstado;
    _categoria = widget.filtrosActuales.categoria;
  }

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

    // Pendientes y Aprobados solo si se muestran filtros avanzados.
    if (widget.mostrarFiltrosAvanzados) {
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

  void _limpiarFiltros() {
    setState(() {
      _ordenarPor = OrdenarPor.masRecientes;
      _filtroEstado = FiltroEstado.todos;
      _categoria = null;
    });
  }

  void _aplicarFiltros() {
    widget.onAplicar(FiltrosEventos(
      ordenarPor: _ordenarPor,
      filtroEstado: _filtroEstado,
      categoria: _categoria,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            valorSeleccionado: _ordenarPor,
            elementos: _obtenerItemsOrdenamiento(),
            onChanged: (valor) {
              setState(() => _ordenarPor = valor!);
            },
          ),
          const SizedBox(height: 16),

          // Dropdown de estado.
          CustomDropdown<FiltroEstado>(
            etiqueta: 'Estado',
            textoHint: 'Selecciona un estado',
            iconoPrefijo: Icons.filter_alt_outlined,
            valorSeleccionado: _filtroEstado,
            elementos: _obtenerItemsEstado(),
            onChanged: (valor) {
              setState(() => _filtroEstado = valor!);
            },
          ),
          const SizedBox(height: 16),

          // Dropdown de categoría.
          CustomDropdown<String>(
            etiqueta: 'Categoría',
            textoHint: 'Selecciona una categoría',
            iconoPrefijo: Icons.category_outlined,
            valorSeleccionado: _categoria,
            elementos: _obtenerItemsCategorias(),
            onChanged: (valor) {
              setState(() => _categoria = valor);
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
                  onPressed: _limpiarFiltros,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  texto: 'Aplicar',
                  tipo: CustomButtonType.primary,
                  onPressed: _aplicarFiltros,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Chips de filtro rápido para eventos.
class ChipsFiltroEstado extends StatelessWidget {
  // Estado seleccionado actualmente.
  final FiltroEstado filtroSeleccionado;

  // Si es true, muestra las opciones "Pendientes" y "Aprobados".
  final bool mostrarFiltrosAvanzados;

  // Callback cuando se selecciona un filtro.
  final ValueChanged<FiltroEstado> onSeleccionar;

  const ChipsFiltroEstado({
    super.key,
    required this.filtroSeleccionado,
    this.mostrarFiltrosAvanzados = false,
    required this.onSeleccionar,
  });

  List<DropdownItem<FiltroEstado>> _obtenerItems() {
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

    if (mostrarFiltrosAvanzados) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _obtenerItems();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final seleccionado = item.valor == filtroSeleccionado;
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
                  onSeleccionar(item.valor);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Obtiene el nombre legible del filtro de estado.
String obtenerNombreFiltroEstado(FiltroEstado filtro) {
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
