import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/view/pages/home_page.dart';
import 'package:escomevents_app/features/auth/view/pages/login_page.dart';
import 'package:escomevents_app/features/auth/view/pages/registro_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/admin_eventos_page.dart';
import 'package:escomevents_app/features/eventos/views/pages/eventos.dart';
import 'package:escomevents_app/features/eventos/views/pages/mis_eventos_page.dart';
import 'package:escomevents_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Nombres de las rutas de la aplicación.
abstract class RutasApp {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String bienvenida = '/';
  static const String inicio = '/inicio';
  static const String eventos = '/eventos';
  static const String misEventos = '/mis-eventos';
  static const String adminEventos = '/admin-eventos';
}

// Rutas públicas que no requieren autenticación.
const _rutasPublicas = [RutasApp.login, RutasApp.registro];

// Rutas exclusivas para organizadores y administradores.
const _rutasOrganizador = [RutasApp.misEventos];

// Rutas exclusivas para administradores.
const _rutasAdministrador = [RutasApp.adminEventos];

// Provider para el router que depende del estado de autenticación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RutasApp.login,
    redirect: (context, state) {
      // Verifica si el usuario está autenticado.
      final estaAutenticado = supabase.auth.currentSession != null;
      final rutaActual = state.uri.path;
      final esRutaPublica = _rutasPublicas.contains(rutaActual);

      // Si no está autenticado y trata de acceder a una ruta protegida.
      if (!estaAutenticado && !esRutaPublica) {
        return RutasApp.login;
      }

      // Si está autenticado y trata de acceder al login o registro.
      if (estaAutenticado && esRutaPublica) {
        return RutasApp.inicio;
      }

      // Verificar permisos basados en rol.
      if (estaAutenticado) {
        final container = ProviderScope.containerOf(context);
        final perfil = container.read(perfilActualProvider);
        final rol = perfil?.rol ?? RolUsuario.estudiante;

        // Rutas de organizador: solo organizadores y administradores.
        if (_rutasOrganizador.contains(rutaActual)) {
          if (rol != RolUsuario.organizador && rol != RolUsuario.administrador) {
            return RutasApp.inicio;
          }
        }

        // Rutas de administrador: solo administradores.
        if (_rutasAdministrador.contains(rutaActual)) {
          if (rol != RolUsuario.administrador) {
            return RutasApp.inicio;
          }
        }
      }

      // No redirigir.
      return null;
    },
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
      // Shell route para la navegación con BottomNavigationBar.
      ShellRoute(
        builder: (context, state, child) {
          return BienvenidaPage(child: child);
        },
        routes: [
          // Rutas accesibles para todos los usuarios autenticados.
          GoRoute(
            path: RutasApp.bienvenida,
            name: 'bienvenida',
            redirect: (context, state) => RutasApp.inicio,
          ),
          GoRoute(
            path: RutasApp.inicio,
            name: 'inicio',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RutasApp.eventos,
            name: 'eventos',
            builder: (context, state) => const EventsScreen(),
          ),
          // Rutas exclusivas para organizadores y administradores.
          GoRoute(
            path: RutasApp.misEventos,
            name: 'misEventos',
            builder: (context, state) {
              final container = ProviderScope.containerOf(context);
              final perfil = container.read(perfilActualProvider);
              final rol = perfil?.rol ?? RolUsuario.organizador;
              return MisEventosPage(rol: rol);
            },
          ),
          // Rutas exclusivas para administradores.
          GoRoute(
            path: RutasApp.adminEventos,
            name: 'adminEventos',
            builder: (context, state) => const AdminEventosPage(),
          ),
        ],
      ),
    ],
  );
});
