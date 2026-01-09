import 'package:escomevents_app/features/home/models/perfil_model.dart';

// Estados posibles de la autenticación.
sealed class AuthState {
  const AuthState();
}

// Estado inicial de la autenticación.
class AuthInicial extends AuthState {
  const AuthInicial();
}

// Estado de carga durante la autenticación.
class AuthCargando extends AuthState {
  const AuthCargando();
}

// Estado de autenticación exitosa.
class AuthExitoso extends AuthState {
  // Perfil del usuario autenticado.
  final PerfilModel perfil;

  const AuthExitoso({required this.perfil});
}

// Estado de error en la autenticación.
class AuthError extends AuthState {
  // Mensaje de error.
  final String mensaje;

  const AuthError({required this.mensaje});
}

// Estado de usuario no autenticado.
class AuthNoAutenticado extends AuthState {
  const AuthNoAutenticado();
}
