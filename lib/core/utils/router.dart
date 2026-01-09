import 'package:escomevents_app/features/home/models/perfil_model.dart';
import 'package:escomevents_app/features/home/views/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/home/views/pages/home_page.dart';
import 'package:escomevents_app/features/home/views/pages/perfil_page.dart';
import 'package:escomevents_app/features/usuarios/views/pages/lista_usuarios_page.dart';
import 'package:escomevents_app/features/auth/view/pages/login_page.dart';
import 'package:escomevents_app/features/auth/view/pages/recuperar_page.dart';
import 'package:escomevents_app/features/auth/view/pages/registro_page.dart';
import 'package:escomevents_app/features/auth/view/pages/registrar_usuario_page.dart';
import 'package:escomevents_app/core/view/pages/splash_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/admin_eventos_page.dart';
import 'package:escomevents_app/features/eventos/views/pages/eventos.dart';
import 'package:escomevents_app/features/eventos/views/pages/mis_eventos_estudiante_page.dart';
import 'package:escomevents_app/features/eventos/views/pages/mis_eventos_page.dart';
import 'package:escomevents_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart';

// Nombres de las rutas de la aplicación.
abstract class RutasApp {
  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String inicio = '/inicio';
  static const String perfil = '/perfil';
  static const String eventos = '/eventos';
  static const String misEventos = '/mis-eventos';
  static const String misEventosEstudiante = '/mis-eventos-estudiante';
  static const String adminEventos = '/admin-eventos';
  static const String registrarUsuario = '/registrar-usuario';
  static const String listaUsuarios = '/lista-usuarios';
}

// Rutas públicas que no requieren autenticación.
const _rutasPublicas = [RutasApp.splash, RutasApp.login, RutasApp.registro, RutasApp.recuperar];

// Rutas exclusivas para organizadores y administradores.
const _rutasOrganizador = [RutasApp.misEventos];

// Rutas exclusivas para administradores.
const _rutasAdministrador = [
  RutasApp.adminEventos,
  RutasApp.registrarUsuario,
  RutasApp.listaUsuarios,
];

// Rutas exclusivas para estudiantes.
const _rutasEstudiante = [RutasApp.misEventosEstudiante];

// Provider para el router que depende del estado de autenticación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RutasApp.splash,
    redirect: (context, state) {
      // Verifica si el usuario está autenticado.
      final estaAutenticado = supabase.auth.currentSession != null;
      final rutaActual = state.uri.path;
      final esRutaPublica = _rutasPublicas.contains(rutaActual);

      // No redirigir desde splash, ya que esa página maneja la navegación.
      if (rutaActual == RutasApp.splash) {
        return null;
      }

      // Si no está autenticado y trata de acceder a una ruta protegida.
      if (!estaAutenticado && !esRutaPublica) {
        return RutasApp.login;
      }

      // Si está autenticado y trata de acceder al login o registro.
      if (estaAutenticado && (rutaActual == RutasApp.login || rutaActual == RutasApp.registro || rutaActual == RutasApp.recuperar)) {
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

        // Rutas de estudiante: solo estudiantes.
        if (_rutasEstudiante.contains(rutaActual)) {
          if (rol != RolUsuario.estudiante) {
            return RutasApp.inicio;
          }
        }
      }

      // No redirigir.
      return null;
    },
    routes: [
      // Ruta de splash para verificar sesión al iniciar.
      GoRoute(
        path: RutasApp.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
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
        path: RutasApp.recuperar,
        name: 'recuperar',
        builder: (context, state) => const RecuperarPage(),
      ),
      // Ruta de perfil
      GoRoute(
        path: RutasApp.perfil,
        name: 'perfil',
        builder: (context, state) {
          return PerfilPage();
        }
      ),
      // Shell route para la navegación con BottomNavigationBar.
      ShellRoute(
        builder: (context, state, child) {
          return BienvenidaPage(child: child);
        },
        routes: [
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
          GoRoute(
            path: RutasApp.registrarUsuario,
            name: 'registrarUsuario',
            builder: (context, state) => const RegistrarUsuarioPage(),
          ),
          GoRoute(
            path: RutasApp.listaUsuarios,
            name: 'listaUsuarios',
            builder: (context, state) => const ListaUsuariosPage(),
          ),
          // Rutas exclusivas para estudiantes.
          GoRoute(
            path: RutasApp.misEventosEstudiante,
            name: 'misEventosEstudiante',
            builder: (context, state) => const MisEventosEstudiantePage(),
          ),
        ],
      ),
    ],
  );
});
