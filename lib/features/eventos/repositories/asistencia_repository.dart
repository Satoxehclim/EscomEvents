import 'dart:developer';

import 'package:escomevents_app/features/eventos/models/asistencia_model.dart';
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
}
