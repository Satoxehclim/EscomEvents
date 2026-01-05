import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/repositories/categoria_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de categorías.
final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) {
  return CategoriaRepositoryImpl();
});

// Estado de las categorías en caché.
sealed class CategoriasState {
  const CategoriasState();
}

// Estado inicial, aún no se han cargado.
class CategoriasInicial extends CategoriasState {
  const CategoriasInicial();
}

// Cargando categorías.
class CategoriasCargando extends CategoriasState {
  const CategoriasCargando();
}

// Categorías cargadas exitosamente.
class CategoriasExitoso extends CategoriasState {
  final List<CategoriaModel> categorias;

  const CategoriasExitoso({required this.categorias});
}

// Error al cargar categorías.
class CategoriasError extends CategoriasState {
  final String mensaje;

  const CategoriasError({required this.mensaje});
}

// Provider del estado de las categorías.
final categoriasProvider =
    NotifierProvider<CategoriasNotifier, CategoriasState>(
  CategoriasNotifier.new,
);

// Provider de conveniencia para acceder a la lista de categorías.
final listaCategoriasCacheProvider = Provider<List<CategoriaModel>>((ref) {
  final state = ref.watch(categoriasProvider);
  if (state is CategoriasExitoso) {
    return state.categorias;
  }
  return [];
});

// Notifier que maneja el estado de las categorías.
class CategoriasNotifier extends Notifier<CategoriasState> {
  late final CategoriaRepository _repository;

  @override
  CategoriasState build() {
    _repository = ref.watch(categoriaRepositoryProvider);
    return const CategoriasInicial();
  }

  // Carga las categorías desde la base de datos.
  Future<void> cargarCategorias() async {
    // Si ya están cargadas, no vuelve a cargar.
    if (state is CategoriasExitoso) return;

    state = const CategoriasCargando();

    try {
      final categorias = await _repository.obtenerCategorias();
      state = CategoriasExitoso(categorias: categorias);
    } catch (e) {
      state = CategoriasError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Fuerza la recarga de categorías.
  Future<void> recargarCategorias() async {
    state = const CategoriasCargando();

    try {
      final categorias = await _repository.obtenerCategorias();
      state = CategoriasExitoso(categorias: categorias);
    } catch (e) {
      state = CategoriasError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Limpia el caché de categorías (al cerrar sesión).
  void limpiarCache() {
    state = const CategoriasInicial();
  }
}
