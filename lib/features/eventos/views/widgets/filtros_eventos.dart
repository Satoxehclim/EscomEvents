import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_dropdown.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/categoria_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modelo extendido de filtros que incluye la categoría completa para UI.
class FiltrosEventosUI {
  final FiltroEstado estado;
  final OrdenEvento orden;
  final CategoriaModel? categoria;

  const FiltrosEventosUI({
    this.estado = FiltroEstado.todos,
    this.orden = OrdenEvento.masRecientes,
    this.categoria,
  });

  FiltrosEventosUI copyWith({
    FiltroEstado? estado,
    OrdenEvento? orden,
    CategoriaModel? categoria,
    bool limpiarCategoria = false,
  }) {
    return FiltrosEventosUI(
      estado: estado ?? this.estado,
      orden: orden ?? this.orden,
      categoria: limpiarCategoria ? null : (categoria ?? this.categoria),
    );
  }

  // Limpia los filtros a valores por defecto.
  FiltrosEventosUI limpiar() {
    return const FiltrosEventosUI();
  }

  // Convierte a FiltroEventos para el repositorio.
  FiltroEventos toFiltroEventos() {
    return FiltroEventos(
      estado: estado,
      orden: orden,
      idCategoria: categoria?.id,
    );
  }
}

// Modal de filtros reutilizable para eventos.
//
// Puede mostrar diferentes opciones de estado según [mostrarFiltrosAvanzados].
class ModalFiltrosEventos extends ConsumerStatefulWidget {
  // Filtros actuales.
  final FiltrosEventosUI filtrosActuales;

  // Si es true, muestra las opciones "Pendientes" y "Aprobados".
  final bool mostrarFiltrosAvanzados;

  // Callback cuando se aplican los filtros.
  final ValueChanged<FiltrosEventosUI> onAplicar;

  const ModalFiltrosEventos({
    super.key,
    required this.filtrosActuales,
    this.mostrarFiltrosAvanzados = false,
    required this.onAplicar,
  });

  @override
  ConsumerState<ModalFiltrosEventos> createState() =>
      _ModalFiltrosEventosState();

  // Muestra el modal de filtros.
  static void mostrar({
    required BuildContext context,
    required FiltrosEventosUI filtrosActuales,
    bool mostrarFiltrosAvanzados = false,
    required ValueChanged<FiltrosEventosUI> onAplicar,
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

class _ModalFiltrosEventosState extends ConsumerState<ModalFiltrosEventos> {
  late OrdenEvento _orden;
  late FiltroEstado _estado;
  late CategoriaModel? _categoria;

  @override
  void initState() {
    super.initState();
    _orden = widget.filtrosActuales.orden;
    _estado = widget.filtrosActuales.estado;
    _categoria = widget.filtrosActuales.categoria;
  }

  // Items para el dropdown de ordenamiento.
  List<DropdownItem<OrdenEvento>> _obtenerItemsOrdenamiento() {
    return const [
      DropdownItem(
        valor: OrdenEvento.masRecientes,
        etiqueta: 'Más recientes (fecha de creación)',
        icono: Icons.schedule,
      ),
      DropdownItem(
        valor: OrdenEvento.masAntiguos,
        etiqueta: 'Más antiguos (fecha de creación)',
        icono: Icons.history,
      ),
      DropdownItem(
        valor: OrdenEvento.masProximos,
        etiqueta: 'Más próximos (fecha del evento)',
        icono: Icons.event_available,
      ),
      DropdownItem(
        valor: OrdenEvento.masLejanos,
        etiqueta: 'Más lejanos (fecha del evento)',
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

    // Pendientes, En Corrección y Aprobados solo si se muestran filtros avanzados.
    if (widget.mostrarFiltrosAvanzados) {
      itemsBase.addAll(const [
        DropdownItem(
          valor: FiltroEstado.pendientes,
          etiqueta: 'Pendientes',
          icono: Icons.pending_actions,
        ),
        DropdownItem(
          valor: FiltroEstado.enCorreccion,
          etiqueta: 'En Corrección',
          icono: Icons.edit_note,
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

  // Obtiene las categorías desde el caché.
  List<DropdownItem<CategoriaModel>> _obtenerItemsCategorias() {
    final categorias = ref.watch(listaCategoriasCacheProvider);
    return categorias.map((cat) {
      return DropdownItem(
        valor: cat,
        etiqueta: cat.nombre,
        icono: cat.icono ?? Icons.category,
      );
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _orden = OrdenEvento.masRecientes;
      _estado = FiltroEstado.todos;
      _categoria = null;
    });
  }

  void _aplicarFiltros() {
    widget.onAplicar(FiltrosEventosUI(
      orden: _orden,
      estado: _estado,
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
          CustomDropdown<OrdenEvento>(
            etiqueta: 'Ordenar por',
            textoHint: 'Selecciona un orden',
            iconoPrefijo: Icons.sort,
            valorSeleccionado: _orden,
            elementos: _obtenerItemsOrdenamiento(),
            onChanged: (valor) {
              setState(() => _orden = valor!);
            },
          ),
          const SizedBox(height: 16),

          // Dropdown de estado.
          CustomDropdown<FiltroEstado>(
            etiqueta: 'Estado',
            textoHint: 'Selecciona un estado',
            iconoPrefijo: Icons.filter_alt_outlined,
            valorSeleccionado: _estado,
            elementos: _obtenerItemsEstado(),
            onChanged: (valor) {
              setState(() => _estado = valor!);
            },
          ),
          const SizedBox(height: 16),

          // Dropdown de categoría.
          CustomDropdown<CategoriaModel>(
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
      itemsBase.insertAll(0,const [
        DropdownItem(
          valor: FiltroEstado.pendientes,
          etiqueta: 'Pendientes',
          icono: Icons.pending_actions,
        ),
        DropdownItem(
          valor: FiltroEstado.enCorreccion,
          etiqueta: 'En Corrección',
          icono: Icons.edit_note,
        ),
        DropdownItem(
          valor: FiltroEstado.aprobados,
          etiqueta: 'Aprobados',
          icono: Icons.check_circle_outline,
        ),
      ]);
      itemsBase.add( const DropdownItem(
        valor: FiltroEstado.todos,
        etiqueta: 'Todos',
        icono: Icons.all_inclusive,
      ));
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
