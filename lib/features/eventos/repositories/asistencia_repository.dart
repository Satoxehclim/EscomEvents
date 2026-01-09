import 'dart:developer';

import 'package:escomevents_app/features/eventos/models/asistencia_model.dart';
import 'package:escomevents_app/features/eventos/models/asistente_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider del repositorio de asistencia.
final asistenciaRepositoryProvider = Provider<AsistenciaRepository>((ref) {
  return AsistenciaRepositoryImpl();
});

// Repositorio abstracto para operaciones con asistencias.
abstract class AsistenciaRepository {
  // Registra la asistencia de un estudiante a un evento.
  Future<AsistenciaModel> registrarAsistencia({
    required String idPerfil,
    required int idEvento,
    required bool entradaLibre,
  });

  // Cancela la asistencia de un estudiante a un evento.
  Future<void> cancelarAsistencia(int idAsistencia);

  // Verifica si un estudiante ya está registrado en un evento.
  Future<AsistenciaModel?> obtenerAsistencia({
    required String idPerfil,
    required int idEvento,
  });

  // Obtiene todas las asistencias de un estudiante.
  Future<List<AsistenciaModel>> obtenerAsistenciasPorPerfil(String idPerfil);

  // Obtiene todas las asistencias de un evento.
  Future<List<AsistenciaModel>> obtenerAsistenciasPorEvento(int idEvento);

  // Marca la asistencia de un estudiante (asistio = 1).
  Future<AsistenciaModel> marcarAsistencia({
    required String idPerfil,
    required int idEvento,
  });

  // Obtiene la lista de asistentes de un evento con información del perfil.
  // Si entradaLibre es true, obtiene todos los registrados.
  // Si entradaLibre es false, obtiene solo los que tienen asistio = 1.
  Future<List<AsistenteModel>> obtenerAsistentesEvento({
    required int idEvento,
    required bool entradaLibre,
  });
}

// Implementación del repositorio de asistencia usando Supabase.
class AsistenciaRepositoryImpl implements AsistenciaRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<AsistenciaModel> registrarAsistencia({
    required String idPerfil,
    required int idEvento,
    required bool entradaLibre,
  }) async {
    try {
      final response = await _supabase
          .from('Asistencia')
          .insert({
            'id_perfil': idPerfil,
            'id_evento': idEvento,
          })
          .select()
          .single();
      return AsistenciaModel.fromMap(response);
    } on PostgrestException catch (e) {
      log(
        'Error al registrar asistencia: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      throw Exception('Error al registrar asistencia: ${e.message}');
    } catch (e) {
      log(
        'Error inesperado al registrar asistencia: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      throw Exception('Error inesperado al registrar asistencia');
    }
  }

  @override
  Future<void> cancelarAsistencia(int idAsistencia) async {
    try {
      await _supabase
          .from('Asistencia')
          .delete()
          .eq('id_asistencia', idAsistencia);
    } on PostgrestException catch (e) {
      log(
        'Error al cancelar asistencia: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      throw Exception('Error al cancelar asistencia: ${e.message}');
    } catch (e) {
      log(
        'Error inesperado al cancelar asistencia: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      throw Exception('Error inesperado al cancelar asistencia');
    }
  }

  @override
  Future<AsistenciaModel?> obtenerAsistencia({
    required String idPerfil,
    required int idEvento,
  }) async {
    try {
      final response = await _supabase
          .from('Asistencia')
          .select()
          .eq('id_perfil', idPerfil)
          .eq('id_evento', idEvento)
          .maybeSingle();

      if (response == null) return null;
      return AsistenciaModel.fromMap(response);
    } on PostgrestException catch (e) {
      log(
        'Error al obtener asistencia: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      return null;
    } catch (e) {
      log(
        'Error inesperado al obtener asistencia: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<List<AsistenciaModel>> obtenerAsistenciasPorPerfil(
    String idPerfil,
  ) async {
    try {
      final response = await _supabase
          .from('Asistencia')
          .select()
          .eq('id_perfil', idPerfil);

      return (response as List)
          .map((e) => AsistenciaModel.fromMap(e))
          .toList();
    } on PostgrestException catch (e) {
      log(
        'Error al obtener asistencias por perfil: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    } catch (e) {
      log(
        'Error inesperado al obtener asistencias por perfil: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<List<AsistenciaModel>> obtenerAsistenciasPorEvento(
    int idEvento,
  ) async {
    try {
      final response = await _supabase
          .from('Asistencia')
          .select()
          .eq('id_evento', idEvento);

      return (response as List)
          .map((e) => AsistenciaModel.fromMap(e))
          .toList();
    } on PostgrestException catch (e) {
      log(
        'Error al obtener asistencias por evento: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    } catch (e) {
      log(
        'Error inesperado al obtener asistencias por evento: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<AsistenciaModel> marcarAsistencia({
    required String idPerfil,
    required int idEvento,
  }) async {
    try {
      // Verifica si existe el registro de asistencia.
      final asistenciaExistente = await obtenerAsistencia(
        idPerfil: idPerfil,
        idEvento: idEvento,
      );

      if (asistenciaExistente == null) {
        throw Exception('El estudiante no está registrado en este evento');
      }

      if (asistenciaExistente.asistio == 1) {
        throw Exception('La asistencia ya fue registrada previamente');
      }

      // Actualiza el registro de asistencia.
      final response = await _supabase
          .from('Asistencia')
          .update({'asistio': 1})
          .eq('id_perfil', idPerfil)
          .eq('id_evento', idEvento)
          .select()
          .single();

      return AsistenciaModel.fromMap(response);
    } on PostgrestException catch (e) {
      log(
        'Error al marcar asistencia: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      throw Exception('Error al marcar asistencia: ${e.message}');
    } catch (e) {
      log(
        'Error al marcar asistencia: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<AsistenteModel>> obtenerAsistentesEvento({
    required int idEvento,
    required bool entradaLibre,
  }) async {
    try {
      // Consulta con join a la tabla Perfil para obtener nombre y avatar.
      PostgrestFilterBuilder query = _supabase
          .from('Asistencia')
          .select('*, perfil:Perfil!id_perfil(id_perfil, nombre, avatar)')
          .eq('id_evento', idEvento);

      // Si no es entrada libre, solo obtener los que tienen asistio = 1.
      if (!entradaLibre) {
        query = query.eq('asistio', 1);
      }

      final response = await query;

      return (response as List)
          .map((e) => AsistenteModel.fromMap(e))
          .toList();
    } on PostgrestException catch (e) {
      log(
        'Error al obtener asistentes del evento: ${e.message}',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    } catch (e) {
      log(
        'Error inesperado al obtener asistentes del evento: $e',
        name: 'AsistenciaRepository',
        error: e,
      );
      return [];
    }
  }
}
