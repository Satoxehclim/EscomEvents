import 'package:escomevents_app/features/auth/models/auth_state.dart';
import 'package:escomevents_app/features/auth/models/perfil_model.dart';
import 'package:escomevents_app/features/auth/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Provider del estado de autenticación.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Provider del perfil del usuario actual.
final perfilActualProvider = Provider<PerfilModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthExitoso) {
    return authState.perfil;
  }
  return null;
});

// Notifier que maneja el estado de autenticación.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthInicial();
  }

  // Verifica si hay una sesión activa al iniciar la app.
  Future<void> verificarSesion() async {
    if (!_repository.haySessionActiva) {
      state = const AuthNoAutenticado();
      return;
    }

    state = const AuthCargando();

    try {
      final perfil = await _repository.obtenerPerfilActual();
      if (perfil != null) {
        state = AuthExitoso(perfil: perfil);
      } else {
        state = const AuthNoAutenticado();
      }
    } catch (e) {
      state = const AuthNoAutenticado();
    }
  }

  // Inicia sesión con correo y contraseña.
  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    state = const AuthCargando();

    try {
      final perfil = await _repository.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );
      state = AuthExitoso(perfil: perfil);
      return true;
    } catch (e) {
      state = AuthError(mensaje: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Registra un nuevo usuario.
  Future<bool> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    state = const AuthCargando();

    try {
      final perfil = await _repository.registrar(
        nombre: nombre,
        correo: correo,
        contrasena: contrasena,
      );
      state = AuthExitoso(perfil: perfil);
      return true;
    } catch (e) {
      state = AuthError(mensaje: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Cierra la sesión del usuario.
  Future<void> cerrarSesion() async {
    state = const AuthCargando();
    try {
      await _repository.cerrarSesion();
      state = const AuthNoAutenticado();
    } catch (e) {
      state = AuthError(mensaje: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Limpia el error actual.
  void limpiarError() {
    if (state is AuthError) {
      state = const AuthNoAutenticado();
    }
  }
}
