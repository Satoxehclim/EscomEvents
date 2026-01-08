import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Página de inicio (Home) de la aplicación.
//
// Muestra un resumen general para el usuario.
class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final perfil = ref.watch(perfilActualProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de bienvenida.
              _construirEncabezado(context, ref, theme, isDark, perfil?.nombre),
              const SizedBox(height: 24),

              // Tarjetas de acceso rápido.
              _construirSeccionAccesoRapido(context, ref, theme, isDark),
              const SizedBox(height: 24),

              // Próximos eventos destacados.
              _construirSeccionProximosEventos(context, theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirEncabezado(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    String? nombreUsuario,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola${nombreUsuario != null ? ', $nombreUsuario' : ''}!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a EscomEvents',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        // Avatar del usuario con menú.
        PopupMenuButton<String>(
          onSelected: (valor) async {
            if (valor == 'cerrar_sesion') {
              await ref.read(authProvider.notifier).cerrarSesion();
              if (context.mounted) {
                context.go(RutasApp.login);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'cerrar_sesion',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Cerrar sesión'),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 28,
            backgroundColor:
                isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirSeccionAccesoRapido(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final perfil = ref.watch(perfilActualProvider);
    final esAdmin = perfil?.rol == RolUsuario.administrador;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso rápido',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TarjetaAccesoRapido(
                icono: Icons.event,
                titulo: 'Eventos',
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                onTap: () {
                  // TODO: Navegar a eventos o cambiar tab.
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaAccesoRapido(
                icono: Icons.notifications,
                titulo: 'Notificaciones',
                color: isDark
                    ? AppColors.darkSecondary
                    : AppColors.lightSecondary,
                onTap: () {
                  // TODO: Navegar a notificaciones.
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaAccesoRapido(
                icono: Icons.person,
                titulo: 'Perfil',
                color: const Color(0xFFF59E0B), // Amber.
                onTap: () {
                  // TODO: Navegar a perfil.
                },
              ),
            ),
          ],
        ),
        
      ],
    );
  }

  Widget _construirSeccionProximosEventos(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximos eventos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todos los eventos.
              },
              child: Text(
                'Ver todos',
                style: TextStyle(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de eventos próximos (placeholder).
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aquí aparecerán tus próximos eventos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Tarjeta de acceso rápido reutilizable.
class _TarjetaAccesoRapido extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback? onTap;

  const _TarjetaAccesoRapido({
    required this.icono,
    required this.titulo,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
