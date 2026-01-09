import 'package:escomevents_app/features/usuarios/models/filtro_usuarios_model.dart';
import 'package:escomevents_app/features/home/models/perfil_model.dart';
import 'package:escomevents_app/features/usuarios/repositories/usuario_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de usuarios.
final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepositoryImpl();
});

// Estado para la lista de usuarios.
sealed class ListaUsuariosState {
  const ListaUsuariosState();
}

class ListaUsuariosInicial extends ListaUsuariosState {
  const ListaUsuariosInicial();
}

class ListaUsuariosCargando extends ListaUsuariosState {
  const ListaUsuariosCargando();
}

class ListaUsuariosCargado extends ListaUsuariosState {
  final List<PerfilModel> usuarios;
  final bool hayMas;
  final int paginaActual;
  final int totalUsuarios;
  final FiltroUsuarios filtro;
  final bool cargandoMas;

  const ListaUsuariosCargado({
    required this.usuarios,
    required this.hayMas,
    required this.paginaActual,
    required this.totalUsuarios,
    required this.filtro,
    this.cargandoMas = false,
  });

  ListaUsuariosCargado copyWith({
    List<PerfilModel>? usuarios,
    bool? hayMas,
    int? paginaActual,
    int? totalUsuarios,
    FiltroUsuarios? filtro,
    bool? cargandoMas,
  }) {
    return ListaUsuariosCargado(
      usuarios: usuarios ?? this.usuarios,
      hayMas: hayMas ?? this.hayMas,
      paginaActual: paginaActual ?? this.paginaActual,
      totalUsuarios: totalUsuarios ?? this.totalUsuarios,
      filtro: filtro ?? this.filtro,
      cargandoMas: cargandoMas ?? this.cargandoMas,
    );
  }
}

class ListaUsuariosError extends ListaUsuariosState {
  final String mensaje;

  const ListaUsuariosError({required this.mensaje});
}

// Provider para la lista de usuarios.
final listaUsuariosProvider =
    NotifierProvider<ListaUsuariosNotifier, ListaUsuariosState>(
  ListaUsuariosNotifier.new,
);

// Notifier para manejar la lista de usuarios.
class ListaUsuariosNotifier extends Notifier<ListaUsuariosState> {
  late final UsuarioRepository _repository;
  static const int _tamanoPagina = 15;
  FiltroUsuarios _filtroActual = const FiltroUsuarios();

  @override
  ListaUsuariosState build() {
    _repository = ref.watch(usuarioRepositoryProvider);
    return const ListaUsuariosInicial();
  }

  // Carga la lista de usuarios.
  Future<void> cargarUsuarios({FiltroUsuarios? filtro}) async {
    _filtroActual = filtro ?? const FiltroUsuarios();
    state = const ListaUsuariosCargando();

    try {
      final resultado = await _repository.obtenerUsuarios(
        pagina: 0,
        tamanoPagina: _tamanoPagina,
        filtro: _filtroActual,
      );

      state = ListaUsuariosCargado(
        usuarios: resultado.usuarios,
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
        totalUsuarios: resultado.totalUsuarios,
        filtro: _filtroActual,
      );
    } catch (e) {
      state = ListaUsuariosError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Carga más usuarios (paginación).
  Future<void> cargarMasUsuarios() async {
    final estadoActual = state;
    if (estadoActual is! ListaUsuariosCargado) return;
    if (!estadoActual.hayMas || estadoActual.cargandoMas) return;

    state = estadoActual.copyWith(cargandoMas: true);

    try {
      final resultado = await _repository.obtenerUsuarios(
        pagina: estadoActual.paginaActual + 1,
        tamanoPagina: _tamanoPagina,
        filtro: _filtroActual,
      );

      state = ListaUsuariosCargado(
        usuarios: [...estadoActual.usuarios, ...resultado.usuarios],
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
        totalUsuarios: resultado.totalUsuarios,
        filtro: _filtroActual,
      );
    } catch (e) {
      state = estadoActual.copyWith(cargandoMas: false);
    }
  }

  // Elimina un usuario de la lista y la base de datos.
  Future<bool> eliminarUsuario(String idPerfil) async {
    try {
      await _repository.eliminarUsuario(idPerfil);

      final estadoActual = state;
      if (estadoActual is ListaUsuariosCargado) {
        final usuariosActualizados = estadoActual.usuarios
            .where((u) => u.idPerfil != idPerfil)
            .toList();
        
        state = estadoActual.copyWith(
          usuarios: usuariosActualizados,
          totalUsuarios: estadoActual.totalUsuarios - 1,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

// Estado para la eliminación de usuario.
sealed class EliminarUsuarioState {
  const EliminarUsuarioState();
}

class EliminarUsuarioInicial extends EliminarUsuarioState {
  const EliminarUsuarioInicial();
}

class EliminarUsuarioCargando extends EliminarUsuarioState {
  const EliminarUsuarioCargando();
}

class EliminarUsuarioExitoso extends EliminarUsuarioState {
  const EliminarUsuarioExitoso();
}

class EliminarUsuarioError extends EliminarUsuarioState {
  final String mensaje;
  const EliminarUsuarioError({required this.mensaje});
}

// Provider para eliminar usuario.
final eliminarUsuarioProvider =
    NotifierProvider<EliminarUsuarioNotifier, EliminarUsuarioState>(
  EliminarUsuarioNotifier.new,
);

// Notifier para eliminar usuarios.
class EliminarUsuarioNotifier extends Notifier<EliminarUsuarioState> {
  late final UsuarioRepository _repository;

  @override
  EliminarUsuarioState build() {
    _repository = ref.watch(usuarioRepositoryProvider);
    return const EliminarUsuarioInicial();
  }

  Future<bool> eliminar(String idPerfil) async {
    state = const EliminarUsuarioCargando();

    try {
      await _repository.eliminarUsuario(idPerfil);
      state = const EliminarUsuarioExitoso();
      return true;
    } catch (e) {
      state = EliminarUsuarioError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reiniciar() {
    state = const EliminarUsuarioInicial();
  }
}
