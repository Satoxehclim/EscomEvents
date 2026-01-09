import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/eventos/models/asistente_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/asistencia_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Página que muestra la lista de asistentes de un evento.
class ListaAsistentesPage extends ConsumerStatefulWidget {
  final int idEvento;
  final String nombreEvento;
  final bool entradaLibre;

  const ListaAsistentesPage({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
    required this.entradaLibre,
  });

  @override
  ConsumerState<ListaAsistentesPage> createState() =>
      _ListaAsistentesPageState();
}

class _ListaAsistentesPageState extends ConsumerState<ListaAsistentesPage> {
  @override
  void initState() {
    super.initState();
    // Carga los asistentes al iniciar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listaAsistentesProvider.notifier).cargarAsistentes(
            idEvento: widget.idEvento,
            entradaLibre: widget.entradaLibre,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estado = ref.watch(listaAsistentesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asistentes', style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),),
            Text(
              widget.nombreEvento,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.white70,
              ),
            ),
          ],
        ),
        leading: BackButton(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: () {
        //       ref.read(listaAsistentesProvider.notifier).cargarAsistentes(
        //             idEvento: widget.idEvento,
        //             entradaLibre: widget.entradaLibre,
        //           );
        //     },
        //     tooltip: 'Recargar',
        //   ),
        // ],
      ),
      body: _construirContenido(estado, theme, isDark),
    );
  }

  Widget _construirContenido(
    ListaAsistentesState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      ListaAsistentesInicial() ||
      ListaAsistentesCargando() =>
        const Center(child: CircularProgressIndicator()),
      ListaAsistentesError(:final mensaje) => _construirError(mensaje, theme),
      ListaAsistentesExito(:final asistentes) =>
        _construirLista(asistentes, theme, isDark),
    };
  }

  Widget _construirError(String mensaje, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(listaAsistentesProvider.notifier).cargarAsistentes(
                      idEvento: widget.idEvento,
                      entradaLibre: widget.entradaLibre,
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLista(
    List<AsistenteModel> asistentes,
    ThemeData theme,
    bool isDark,
  ) {
    if (asistentes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.entradaLibre
                    ? 'Aún no hay estudiantes registrados'
                    : 'Aún no se ha registrado la asistencia de ningún estudiante',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Encabezado con total de asistentes.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.5)
                : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.entradaLibre
                    ? 'Total registrados: ${asistentes.length}'
                    : 'Total asistentes: ${asistentes.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Lista de asistentes.
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: asistentes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final asistente = asistentes[index];
              return _TarjetaAsistente(
                asistente: asistente,
                entradaLibre: widget.entradaLibre,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget que muestra la información de un asistente.
class _TarjetaAsistente extends StatelessWidget {
  final AsistenteModel asistente;
  final bool entradaLibre;

  const _TarjetaAsistente({
    required this.asistente,
    required this.entradaLibre,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: _construirAvatar(isDark),
      title: Text(
        asistente.nombre,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: !entradaLibre ? _construirBadgeAsistencia(theme, isDark) : null,
    );
  }

  Widget _construirAvatar(bool isDark) {
    final tieneAvatar = asistente.avatar != null && asistente.avatar!.isNotEmpty;

    if (tieneAvatar) {
      return CircleAvatar(
        backgroundImage: NetworkImage(asistente.avatar!),
        backgroundColor:
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      backgroundColor:
          isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }

  Widget _construirBadgeAsistencia(ThemeData theme, bool isDark) {
    // En eventos con entrada no libre, solo se muestran los que asistieron.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green,
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 4),
          Text(
            'Asistió',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
