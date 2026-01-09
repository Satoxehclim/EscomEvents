import 'package:escomevents_app/features/eventos/models/asistencia_model.dart';
import 'package:escomevents_app/features/eventos/models/asistente_model.dart';
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

// Resultado del escaneo de asistencia.
sealed class ResultadoEscaneoAsistencia {
  const ResultadoEscaneoAsistencia();
}

class EscaneoExitoso extends ResultadoEscaneoAsistencia {
  final String nombreEstudiante;
  const EscaneoExitoso(this.nombreEstudiante);
}

class EscaneoYaRegistrado extends ResultadoEscaneoAsistencia {
  final String nombreEstudiante;
  const EscaneoYaRegistrado(this.nombreEstudiante);
}

class EscaneoNoRegistrado extends ResultadoEscaneoAsistencia {
  const EscaneoNoRegistrado();
}

class EscaneoError extends ResultadoEscaneoAsistencia {
  final String mensaje;
  const EscaneoError(this.mensaje);
}

// Provider para manejar el escaneo de asistencia del organizador.
final escaneoAsistenciaProvider =
    NotifierProvider<EscaneoAsistenciaNotifier, void>(
  EscaneoAsistenciaNotifier.new,
);

// Notifier para manejar el escaneo de asistencia.
class EscaneoAsistenciaNotifier extends Notifier<void> {
  late final AsistenciaRepository _repository;

  @override
  void build() {
    _repository = ref.watch(asistenciaRepositoryProvider);
  }

  // Marca la asistencia de un estudiante escaneando su QR.
  Future<ResultadoEscaneoAsistencia> marcarAsistencia({
    required String idPerfil,
    required String nombreEstudiante,
    required int idEvento,
  }) async {
    try {
      await _repository.marcarAsistencia(
        idPerfil: idPerfil,
        idEvento: idEvento,
      );
      return EscaneoExitoso(nombreEstudiante);
    } catch (e) {
      final mensaje = e.toString().replaceAll('Exception: ', '');
      if (mensaje.contains('ya fue registrada')) {
        return EscaneoYaRegistrado(nombreEstudiante);
      }
      if (mensaje.contains('no está registrado')) {
        return const EscaneoNoRegistrado();
      }
      return EscaneoError(mensaje);
    }
  }
}

// Estado de la lista de asistentes de un evento.
sealed class ListaAsistentesState {
  const ListaAsistentesState();
}

class ListaAsistentesInicial extends ListaAsistentesState {
  const ListaAsistentesInicial();
}

class ListaAsistentesCargando extends ListaAsistentesState {
  const ListaAsistentesCargando();
}

class ListaAsistentesExito extends ListaAsistentesState {
  final List<AsistenteModel> asistentes;
  const ListaAsistentesExito(this.asistentes);
}

class ListaAsistentesError extends ListaAsistentesState {
  final String mensaje;
  const ListaAsistentesError(this.mensaje);
}

// Provider para la lista de asistentes de un evento.
final listaAsistentesProvider =
    NotifierProvider<ListaAsistentesNotifier, ListaAsistentesState>(
  ListaAsistentesNotifier.new,
);

// Notifier para manejar la lista de asistentes.
class ListaAsistentesNotifier extends Notifier<ListaAsistentesState> {
  late final AsistenciaRepository _repository;

  @override
  ListaAsistentesState build() {
    _repository = ref.watch(asistenciaRepositoryProvider);
    return const ListaAsistentesInicial();
  }

  // Carga la lista de asistentes del evento.
  Future<void> cargarAsistentes({
    required int idEvento,
    required bool entradaLibre,
  }) async {
    state = const ListaAsistentesCargando();

    try {
      final asistentes = await _repository.obtenerAsistentesEvento(
        idEvento: idEvento,
        entradaLibre: entradaLibre,
      );
      state = ListaAsistentesExito(asistentes);
    } catch (e) {
      state = ListaAsistentesError('Error al cargar asistentes: $e');
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const ListaAsistentesInicial();
  }
}
