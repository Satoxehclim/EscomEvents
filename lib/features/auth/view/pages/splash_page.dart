import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/features/auth/models/auth_state.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Página de carga inicial que verifica la sesión del usuario.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Verifica la sesión al iniciar la página.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSesionYNavegar();
    });
  }

  Future<void> _verificarSesionYNavegar() async {
    // Verifica si hay una sesión activa.
    await ref.read(authProvider.notifier).verificarSesion();

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState is AuthExitoso) {
      // Si hay sesión activa, navega al inicio.
      context.go(RutasApp.inicio);
    } else {
      // Si no hay sesión, navega al login.
      context.go(RutasApp.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de la app.
            Image.asset(
              'assets/icon/icon.png',
              width: 80,
              height: 80,
            ),
            // Icon(
            //   Icons.event,
            //   size: 80,
            //   color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            // ),
            const SizedBox(height: 24),
            Text(
              'EscomEvents',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
