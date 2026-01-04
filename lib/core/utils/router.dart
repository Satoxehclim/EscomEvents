import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/view/pages/login_page.dart';
import 'package:escomevents_app/features/auth/view/pages/registro_page.dart';
import 'package:go_router/go_router.dart';

// Nombres de las rutas de la aplicación.
abstract class RutasApp {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String bienvenida = '/';
}

// Configuración del enrutador de la aplicación.
final GoRouter appRouter = GoRouter(
  initialLocation: RutasApp.login,
  routes: [
    GoRoute(
      path: RutasApp.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RutasApp.registro,
      name: 'registro',
      builder: (context, state) => const RegistroPage(),
    ),
    GoRoute(
      path: RutasApp.bienvenida,
      name: 'bienvenida',
      builder: (context, state) {
        // Obtiene el rol del usuario de los parámetros extra.
        final rol = state.extra as RolUsuario? ?? RolUsuario.estudiante;
        return BienvenidaPage(rol: rol);
      },
    ),
  ],
);
