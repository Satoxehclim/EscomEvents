import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/eventos/models/calificacion_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_calificaciones_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/calificacion_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Página que muestra las calificaciones de un evento.
class CalificacionesEventoPage extends ConsumerStatefulWidget {
  final int idEvento;
  final String nombreEvento;

  const CalificacionesEventoPage({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
  });

  @override
  ConsumerState<CalificacionesEventoPage> createState() =>
      _CalificacionesEventoPageState();
}

class _CalificacionesEventoPageState
    extends ConsumerState<CalificacionesEventoPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(calificacionesEventoProvider.notifier)
          .cargarCalificaciones(idEvento: widget.idEvento);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Detecta cuando el usuario llega al final de la lista.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(calificacionesEventoProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estado = ref.watch(calificacionesEventoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calificaciones',
          style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con nombre del evento.
          _EncabezadoEvento(nombreEvento: widget.nombreEvento),

          // Resumen y filtros.
          if (estado is CalificacionesEventoCargado) ...[
            _ResumenCalificaciones(
              totalCalificaciones: estado.totalCalificaciones,
              promedioCalificaciones: estado.promedioCalificaciones,
            ),
            _FiltroOrden(
              filtroActual: estado.filtro,
              onFiltroSeleccionado: (nuevoFiltro) {
                ref
                    .read(calificacionesEventoProvider.notifier)
                    .cambiarFiltro(nuevoFiltro);
              },
            ),
          ],
          // TODO: resumen de comentarios con ia
          // Lista de calificaciones.
          Expanded(child: _construirContenido(estado)),
        ],
      ),
    );
  }

  Widget _construirContenido(CalificacionesEventoState estado) {
    if (estado is CalificacionesEventoCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (estado is CalificacionesEventoError) {
      return _EstadoError(
        mensaje: estado.mensaje,
        onReintentar: () {
          ref
              .read(calificacionesEventoProvider.notifier)
              .cargarCalificaciones(idEvento: widget.idEvento);
        },
      );
    }

    if (estado is CalificacionesEventoCargado) {
      if (estado.calificaciones.isEmpty) {
        return const _EstadoVacio();
      }

      return _ListaCalificaciones(
        calificaciones: estado.calificaciones,
        cargandoMas: estado.cargandoMas,
        scrollController: _scrollController,
      );
    }

    return const SizedBox.shrink();
  }
}

// Encabezado con el nombre del evento.
class _EncabezadoEvento extends StatelessWidget {
  final String nombreEvento;

  const _EncabezadoEvento({required this.nombreEvento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(
        nombreEvento,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Resumen de calificaciones con promedio y total.
class _ResumenCalificaciones extends StatelessWidget {
  final int totalCalificaciones;
  final double promedioCalificaciones;

  const _ResumenCalificaciones({
    required this.totalCalificaciones,
    required this.promedioCalificaciones,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: isDark
        //       ? [AppColors.darkPrimary.withOpacity(0.2), Colors.transparent]
        //       : [AppColors.lightPrimary.withOpacity(0.1), Colors.transparent],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkPrimary.withOpacity(0.3)
              : AppColors.lightPrimary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Promedio.
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      promedioCalificaciones.toStringAsFixed(1),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star_rounded,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Promedio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Divisor.
          Container(
            height: 50,
            width: 1,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),

          // Total de calificaciones.
          Expanded(
            child: Column(
              children: [
                Text(
                  '$totalCalificaciones',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCalificaciones == 1
                      ? 'Calificación'
                      : 'Calificaciones',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Filtro de ordenamiento.
class _FiltroOrden extends StatelessWidget {
  final FiltroCalificaciones filtroActual;
  final void Function(FiltroCalificaciones) onFiltroSeleccionado;

  const _FiltroOrden({
    required this.filtroActual,
    required this.onFiltroSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 20,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            'Ordenar por:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PopupMenuButton<OrdenCalificacion>(
              initialValue: filtroActual.orden,
              onSelected: (orden) {
                onFiltroSeleccionado(FiltroCalificaciones(orden: orden));
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withOpacity(0.1)
                      : AppColors.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPrimary.withOpacity(0.3)
                        : AppColors.lightPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        filtroActual.textoOrden,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => OrdenCalificacion.values.map((orden) {
                final filtro = FiltroCalificaciones(orden: orden);
                final esSeleccionado = orden == filtroActual.orden;
                return PopupMenuItem(
                  value: orden,
                  child: Row(
                    children: [
                      if (esSeleccionado)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(filtro.textoOrden),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Lista de calificaciones.
class _ListaCalificaciones extends StatelessWidget {
  final List<CalificacionModel> calificaciones;
  final bool cargandoMas;
  final ScrollController scrollController;

  const _ListaCalificaciones({
    required this.calificaciones,
    required this.cargandoMas,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: calificaciones.length + (cargandoMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == calificaciones.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _TarjetaCalificacion(calificacion: calificaciones[index]);
      },
    );
  }
}

// Tarjeta individual de calificación.
class _TarjetaCalificacion extends StatelessWidget {
  final CalificacionModel calificacion;

  const _TarjetaCalificacion({required this.calificacion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila con estrellas y fecha.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Estrellas.
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < calificacion.calificacion
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < calificacion.calificacion
                        ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                        : Colors.grey.shade400,
                    size: 24,
                  );
                }),
              ),

              // Fecha.
              Text(
                formatoFecha.format(calificacion.fechaCalificacion),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // Comentario (si existe).
          if (calificacion.comentario != null &&
              calificacion.comentario!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                calificacion.comentario!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Estado vacío cuando no hay calificaciones.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: 80,
              color: isDark
                  ? AppColors.darkPrimary.withOpacity(0.5)
                  : AppColors.lightPrimary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin calificaciones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este evento aún no tiene calificaciones de los asistentes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Estado de error.
class _EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoError({
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Error al cargar',
              style: theme.textTheme.titleLarge?.copyWith(
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
              onPressed: onReintentar,
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
}
