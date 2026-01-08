import 'package:escomevents_app/features/eventos/models/calificacion_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_calificaciones_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Resultado paginado de calificaciones.
class ResultadoCalificaciones {
  final List<CalificacionModel> calificaciones;
  final bool hayMas;
  final int paginaActual;
  final int totalCalificaciones;
  final double promedioCalificaciones;

  const ResultadoCalificaciones({
    required this.calificaciones,
    required this.hayMas,
    required this.paginaActual,
    required this.totalCalificaciones,
    required this.promedioCalificaciones,
  });
}

// Repositorio abstracto para operaciones con calificaciones.
abstract class CalificacionRepository {
  // Obtiene las calificaciones de un evento con paginación y filtros.
  Future<ResultadoCalificaciones> obtenerCalificacionesEvento({
    required int idEvento,
    int pagina = 0,
    int tamanoPagina = 10,
    FiltroCalificaciones? filtro,
  });

  // Obtiene el resumen de calificaciones de un evento.
  Future<({int total, double promedio})> obtenerResumenCalificaciones({
    required int idEvento,
  });
}

// Implementación del repositorio de calificaciones usando Supabase.
class CalificacionRepositoryImpl implements CalificacionRepository {
  final SupabaseClient _supabase;

  CalificacionRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<ResultadoCalificaciones> obtenerCalificacionesEvento({
    required int idEvento,
    int pagina = 0,
    int tamanoPagina = 10,
    FiltroCalificaciones? filtro,
  }) async {
    try {
      final filtroActual = filtro ?? const FiltroCalificaciones();
      final desde = pagina * tamanoPagina;
      final hasta = desde + tamanoPagina - 1;

      // Obtiene el total y promedio de calificaciones.
      final resumen = await obtenerResumenCalificaciones(idEvento: idEvento);

      // Construye la query con filtros aplicados directamente.
      final query = _supabase
          .from('Calificacion')
          .select('id_calificacion, id_evento, calificacion, comentario, fecha')
          .eq('id_evento', idEvento)
          .order(
            filtroActual.campoOrden,
            ascending: filtroActual.esAscendente,
          )
          .range(desde, hasta);

      final respuesta = await query;

      final calificaciones = (respuesta as List)
          .map((item) => CalificacionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Determina si hay más páginas.
      final hayMas = calificaciones.length == tamanoPagina &&
          (desde + calificaciones.length) < resumen.total;

      return ResultadoCalificaciones(
        calificaciones: calificaciones,
        hayMas: hayMas,
        paginaActual: pagina,
        totalCalificaciones: resumen.total,
        promedioCalificaciones: resumen.promedio,
      );
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener calificaciones: ${e.message}');
    }
  }

  @override
  Future<({int total, double promedio})> obtenerResumenCalificaciones({
    required int idEvento,
  }) async {
    try {
      // Obtiene el conteo y suma de calificaciones.
      final respuesta = await _supabase
          .from('Calificacion')
          .select('calificacion')
          .eq('id_evento', idEvento);

      final lista = respuesta as List;
      final total = lista.length;

      if (total == 0) {
        return (total: 0, promedio: 0.0);
      }

      final suma = lista.fold<int>(
        0,
        (sum, item) => sum + (item['calificacion'] as int),
      );
      final promedio = suma / total;

      return (total: total, promedio: promedio);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener resumen: ${e.message}');
    }
  }
}
