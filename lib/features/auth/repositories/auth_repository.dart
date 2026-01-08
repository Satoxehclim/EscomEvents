import 'package:escomevents_app/features/auth/models/perfil_model.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositorio abstracto para operaciones de autenticación.
abstract class AuthRepository {
  // Inicia sesión con correo y contraseña.
  Future<PerfilModel> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  // Registra un nuevo usuario.
  Future<PerfilModel> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  });

  // Invita a un nuevo usuario enviando un enlace de invitación al correo.
  Future<void> invitarUsuario({
    required String nombre,
    required String correo,
    required RolUsuario rol,
  });

  // Cierra la sesión del usuario actual.
  Future<void> cerrarSesion();

  // Obtiene el perfil del usuario actual si está autenticado.
  Future<PerfilModel?> obtenerPerfilActual();

  // Verifica si hay una sesión activa.
  bool get haySessionActiva;
}

// Implementación del repositorio de autenticación usando Supabase.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<PerfilModel> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _supabase.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );

      if (respuesta.user == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      // Obtiene el perfil del usuario.
      final perfil = await _obtenerPerfil(respuesta.user!.id);
      return perfil;
    } on AuthException catch (e) {
      throw _manejarErrorAuth(e);
    }
  }

  @override
  Future<PerfilModel> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    try {
      // Genera un URL QR único basado en un timestamp temporal.
      // El trigger lo usará para crear el perfil.
      final urlQrTemporal = 'escomevents://perfil/${DateTime.now().millisecondsSinceEpoch}';
      
      final respuesta = await _supabase.auth.signUp(
        email: correo,
        password: contrasena,
        data: {
          // Estos son los "keys" que luego leerá tu Trigger.
          'nombre': nombre, 
          'rol': 'estudiante',
          'url_qr': urlQrTemporal,
        },
      );

      if (respuesta.user == null) {
        throw Exception('No se pudo completar el registro');
      }

      // Verifica si el usuario necesita confirmar su correo.
      // Si identities está vacío, el usuario ya existe.
      if (respuesta.user!.identities == null || 
          respuesta.user!.identities!.isEmpty) {
        throw Exception('Este correo ya está registrado');
      }

      // Si el correo necesita confirmación, retorna un perfil temporal.
      // El perfil real se obtendrá cuando el usuario inicie sesión después de confirmar.
      if (respuesta.user!.emailConfirmedAt == null) {
        // Retorna un perfil temporal solo con el correo para mostrar en la UI.
        return PerfilModel(
          idPerfil: respuesta.user!.id,
          nombre: nombre,
          urlQr: urlQrTemporal,
          rol: RolUsuario.estudiante,
          requiereConfirmacion: true,
        );
      }

      // Si no requiere confirmación, obtiene el perfil creado por el trigger.
      final perfil = await _obtenerPerfil(respuesta.user!.id);
      return perfil;
    } on AuthException catch (e) {
      throw _manejarErrorAuth(e);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear perfil: ${e.message}');
    }
  }

  @override
  Future<void> invitarUsuario({
    required String nombre,
    required String correo,
    required RolUsuario rol,
  }) async {
    try {
      // Genera un URL QR único para el nuevo usuario.
      final urlQrTemporal =
          'escomevents://perfil/${DateTime.now().millisecondsSinceEpoch}';

      // Convierte el rol a string para el metadata.
      String rolString;
      switch (rol) {
        case RolUsuario.administrador:
          rolString = 'administrador';
          break;
        case RolUsuario.organizador:
          rolString = 'organizador';
          break;
        case RolUsuario.estudiante:
          rolString = 'estudiante';
          break;
      }

      // Genera una contraseña temporal segura.
      // El usuario la cambiará mediante el enlace de restablecimiento.
      final contrasenaTemp =
          'Temp${DateTime.now().millisecondsSinceEpoch}!Aa1';

      // Crea el usuario con signUp.
      final respuesta = await _supabase.auth.signUp(
        email: correo,
        password: contrasenaTemp,
        data: {
          'nombre': nombre,
          'rol': rolString,
          'url_qr': urlQrTemporal,
        },
      );

      if (respuesta.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      // Verifica si el usuario ya existe.
      if (respuesta.user!.identities == null ||
          respuesta.user!.identities!.isEmpty) {
        throw Exception('Este correo ya está registrado');
      }

      // Envía un correo de restablecimiento de contraseña.
      // El usuario usará este enlace para establecer su contraseña real.
      await _supabase.auth.resetPasswordForEmail(correo);
    } on AuthException catch (e) {
      throw _manejarErrorAuth(e);
    } on PostgrestException catch (e) {
      throw Exception('Error al invitar usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error al invitar usuario: $e');
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<PerfilModel?> obtenerPerfilActual() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return null;

    try {
      return await _obtenerPerfil(usuario.id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool get haySessionActiva => _supabase.auth.currentSession != null;

  // Obtiene el perfil de un usuario por su ID.
  Future<PerfilModel> _obtenerPerfil(String idUsuario) async {
    final respuesta = await _supabase
        .from('Perfil')
        .select()
        .eq('id_perfil', idUsuario)
        .single();

    return PerfilModel.fromJson(respuesta);
  }

  // Maneja errores de autenticación de Supabase.
  Exception _manejarErrorAuth(AuthException e) {
    print(e);
    switch (e.message) {
      case 'Invalid login credentials':
        return Exception('Correo o contraseña incorrectos');
      case 'Email not confirmed':
        return Exception('Por favor confirma tu correo electrónico');
      case 'User already registered':
        return Exception('Este correo ya está registrado');
      default:
        return Exception(e.message);
    }
  }
}
