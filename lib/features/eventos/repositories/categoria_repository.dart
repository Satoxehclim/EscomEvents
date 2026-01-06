import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositorio abstracto para operaciones con categorías.
abstract class CategoriaRepository {
  // Obtiene todas las categorías disponibles.
  Future<List<CategoriaModel>> obtenerCategorias();
}

// Implementación del repositorio de categorías usando Supabase.
class CategoriaRepositoryImpl implements CategoriaRepository {
  final SupabaseClient _supabase;

  CategoriaRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final respuesta = await _supabase
          .from('Categoria')
          .select()
          .order('nombre', ascending: true);

      return (respuesta as List)
          .map((json) => CategoriaModel.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener categorías: ${e.message}');
    }
  }
}
