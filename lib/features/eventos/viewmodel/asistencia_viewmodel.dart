import 'package:escomevents_app/features/eventos/models/asistencia_model.dart';
import 'package:escomevents_app/features/eventos/repositories/asistencia_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado de la asistencia a un evento.
sealed class AsistenciaEventoState {
  const AsistenciaEventoState();
}

class AsistenciaEventoInicial extends AsistenciaEventoState {
  const AsistenciaEventoInicial();
}

class AsistenciaEventoCargando extends AsistenciaEventoState {
  const AsistenciaEventoCargando();
}

class AsistenciaEventoNoRegistrado extends AsistenciaEventoState {
  const AsistenciaEventoNoRegistrado();
}

class AsistenciaEventoRegistrado extends AsistenciaEventoState {
  final AsistenciaModel asistencia;

  const AsistenciaEventoRegistrado(this.asistencia);
}

class AsistenciaEventoError extends AsistenciaEventoState {
  final String mensaje;

  const AsistenciaEventoError(this.mensaje);
}

// Provider para manejar asistencia.
final asistenciaProvider =
    NotifierProvider<AsistenciaNotifier, AsistenciaEventoState>(
  AsistenciaNotifier.new,
);

// Notifier para manejar la asistencia a eventos.
class AsistenciaNotifier extends Notifier<AsistenciaEventoState> {
  late final AsistenciaRepository _repository;

  @override
  AsistenciaEventoState build() {
    _repository = ref.watch(asistenciaRepositoryProvider);
    return const AsistenciaEventoInicial();
  }

  // Verifica si el usuario está registrado en el evento.
  Future<void> verificarAsistencia({
    required String idPerfil,
    required int idEvento,
  }) async {
    state = const AsistenciaEventoCargando();

    try {
      final asistencia = await _repository.obtenerAsistencia(
        idPerfil: idPerfil,
        idEvento: idEvento,
      );

      if (asistencia != null) {
        state = AsistenciaEventoRegistrado(asistencia);
      } else {
        state = const AsistenciaEventoNoRegistrado();
      }
    } catch (e) {
      state = AsistenciaEventoError('Error al verificar asistencia: $e');
    }
  }

  // Registra la asistencia del usuario al evento.
  Future<bool> registrarAsistencia({
    required String idPerfil,
    required int idEvento,
    required bool entradaLibre,
  }) async {
    final estadoAnterior = state;
    state = const AsistenciaEventoCargando();

    try {
      final asistencia = await _repository.registrarAsistencia(
        idPerfil: idPerfil,
        idEvento: idEvento,
        entradaLibre: entradaLibre,
      );

      state = AsistenciaEventoRegistrado(asistencia);
      return true;
    } catch (e) {
      state = estadoAnterior;
      return false;
    }
  }

  // Cancela la asistencia del usuario al evento.
  Future<bool> cancelarAsistencia(int idAsistencia) async {
    final estadoAnterior = state;
    state = const AsistenciaEventoCargando();

    try {
      await _repository.cancelarAsistencia(idAsistencia);
      state = const AsistenciaEventoNoRegistrado();
      return true;
    } catch (e) {
      state = estadoAnterior;
      return false;
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const AsistenciaEventoInicial();
  }
}
