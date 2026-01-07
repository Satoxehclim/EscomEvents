import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:flutter/material.dart';

// Widget para mostrar el estado de carga.
class EstadoCargando extends StatelessWidget {
  const EstadoCargando({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
    );
  }
}

// Widget para mostrar el estado de error.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const EstadoError({
    required this.mensaje,
    required this.onReintentar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

// Widget para mostrar el estado vacío.
class EstadoVacio extends StatelessWidget {
  final String mensajePrincipal;
  final String? mensajeSecundario;
  final IconData icono;
  final Color? colorIcono;

  const EstadoVacio({
    required this.mensajePrincipal,
    this.mensajeSecundario,
    this.icono = Icons.event_busy,
    this.colorIcono,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            size: 64,
            color: colorIcono ??
                (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            mensajePrincipal,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (mensajeSecundario != null) ...[
            const SizedBox(height: 8),
            Text(
              mensajeSecundario!,
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

// Widget para mostrar la lista de eventos con paginación.
class ListaEventos extends StatelessWidget {
  final List<EventModel> eventos;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(EventModel) onEventoTap;
  final bool hayMas;
  final bool cargandoMas;
  final Widget estadoVacio;

  const ListaEventos({
    required this.eventos,
    required this.scrollController,
    required this.onRefresh,
    required this.onEventoTap,
    required this.estadoVacio,
    this.hayMas = false,
    this.cargandoMas = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return estadoVacio;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemCount = eventos.length + (cargandoMas || hayMas ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      child: ListView.builder(
        controller: scrollController,
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
            onTap: () => onEventoTap(eventos[index]),
          );
        },
      ),
    );
  }
}

// Widget para el header de la página de eventos.
class HeaderEventos extends StatelessWidget {
  final String titulo;
  final VoidCallback onFiltrosTap;

  const HeaderEventos({
    required this.titulo,
    required this.onFiltrosTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
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
              onPressed: onFiltrosTap,
            ),
          ),
        ],
      ),
    );
  }
}
