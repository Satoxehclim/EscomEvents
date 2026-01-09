import 'package:escomevents_app/features/usuarios/models/filtro_usuarios_model.dart';
import 'package:escomevents_app/features/home/models/perfil_model.dart';
import 'package:escomevents_app/features/home/views/pages/bienvenida_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Resultado paginado de usuarios.
class ResultadoUsuarios {
  final List<PerfilModel> usuarios;
  final bool hayMas;
  final int paginaActual;
  final int totalUsuarios;

  const ResultadoUsuarios({
    required this.usuarios,
    required this.hayMas,
    required this.paginaActual,
    required this.totalUsuarios,
  });
}

// Repositorio abstracto para operaciones con usuarios.
abstract class UsuarioRepository {
  // Obtiene la lista de usuarios con paginación y filtros.
  Future<ResultadoUsuarios> obtenerUsuarios({
    int pagina = 0,
    int tamanoPagina = 15,
    FiltroUsuarios? filtro,
  });

  // Obtiene el total de usuarios según el filtro.
  Future<int> obtenerTotalUsuarios({FiltroUsuarios? filtro});

  // Elimina un usuario por su ID.
  Future<void> eliminarUsuario(String idPerfil);
}

// Implementación del repositorio de usuarios usando Supabase.
class UsuarioRepositoryImpl implements UsuarioRepository {
  final SupabaseClient _supabase;

  UsuarioRepositoryImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<ResultadoUsuarios> obtenerUsuarios({
    int pagina = 0,
    int tamanoPagina = 15,
    FiltroUsuarios? filtro,
  }) async {
    try {
      final desde = pagina * tamanoPagina;
      final hasta = desde + tamanoPagina - 1;

      // Obtiene el total de usuarios con el filtro aplicado.
      final total = await obtenerTotalUsuarios(filtro: filtro);

      // Construye la query base.
      var query = _supabase
          .from('Perfil')
          .select('id_perfil, nombre, avatar, url_qr, rol');

      // Aplica el filtro de rol si está presente.
      if (filtro?.rol != null) {
        query = query.eq('rol', _rolAString(filtro!.rol!));
      }

      // Aplica ordenamiento y paginación.
      final respuesta = await query
          .order('nombre', ascending: true)
          .range(desde, hasta);

      final usuarios = (respuesta as List)
          .map((item) => PerfilModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Determina si hay más páginas.
      final hayMas =
          usuarios.length == tamanoPagina && (desde + usuarios.length) < total;

      return ResultadoUsuarios(
        usuarios: usuarios,
        hayMas: hayMas,
        paginaActual: pagina,
        totalUsuarios: total,
      );
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener usuarios: ${e.message}');
    }
  }

  @override
  Future<int> obtenerTotalUsuarios({FiltroUsuarios? filtro}) async {
    try {
      var query = _supabase.from('Perfil').select('id_perfil');

      if (filtro?.rol != null) {
        query = query.eq('rol', _rolAString(filtro!.rol!));
      }

      final respuesta = await query.count(CountOption.exact);
      return respuesta.count;
    } on PostgrestException catch (e) {
      throw Exception('Error al contar usuarios: ${e.message}');
    }
  }

  @override
  Future<void> eliminarUsuario(String idPerfil) async {
    try {
      // Llama a la función RPC que elimina el perfil y el usuario de auth.users
      await _supabase.rpc(
        'eliminar_usuario_completo',
        params: {'user_id': idPerfil},
      );
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar usuario: ${e.message}');
    }
  }

  // Convierte un RolUsuario a su representación en string.
  String _rolAString(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return 'administrador';
      case RolUsuario.organizador:
        return 'organizador';
      case RolUsuario.estudiante:
        return 'estudiante';
    }
  }
}
