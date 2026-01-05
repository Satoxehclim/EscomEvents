import 'dart:io';

import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/repositories/evento_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de eventos.
final eventoRepositoryProvider = Provider<EventoRepository>((ref) {
  return EventoRepositoryImpl();
});

// Estado para la creación de eventos.
sealed class CrearEventoState {
  const CrearEventoState();
}

class CrearEventoInicial extends CrearEventoState {
  const CrearEventoInicial();
}

class CrearEventoCargando extends CrearEventoState {
  const CrearEventoCargando();
}

class CrearEventoExitoso extends CrearEventoState {
  final EventModel evento;
  const CrearEventoExitoso({required this.evento});
}

class CrearEventoError extends CrearEventoState {
  final String mensaje;
  const CrearEventoError({required this.mensaje});
}

// Provider para crear eventos.
final crearEventoProvider =
    NotifierProvider<CrearEventoNotifier, CrearEventoState>(
  CrearEventoNotifier.new,
);

// Notifier para manejar la creación de eventos.
class CrearEventoNotifier extends Notifier<CrearEventoState> {
  late final EventoRepository _repository;

  @override
  CrearEventoState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const CrearEventoInicial();
  }

  // Crea un nuevo evento.
  Future<bool> crearEvento({
    required String idOrganizador,
    required String nombre,
    required DateTime fecha,
    required String lugar,
    required bool entradaLibre,
    String? descripcion,
    File? imagen,
    File? flyer,
    required List<CategoriaModel> categorias,
  }) async {
    state = const CrearEventoCargando();

    try {
      final evento = await _repository.crearEvento(
        idOrganizador: idOrganizador,
        nombre: nombre,
        fecha: fecha,
        lugar: lugar,
        entradaLibre: entradaLibre,
        descripcion: descripcion,
        imagen: imagen,
        flyer: flyer,
        categorias: categorias,
      );

      state = CrearEventoExitoso(evento: evento);
      return true;
    } catch (e) {
      state = CrearEventoError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const CrearEventoInicial();
  }
}

// Estado para la lista de eventos del organizador.
sealed class EventosOrganizadorState {
  const EventosOrganizadorState();
}

class EventosOrganizadorInicial extends EventosOrganizadorState {
  const EventosOrganizadorInicial();
}

class EventosOrganizadorCargando extends EventosOrganizadorState {
  const EventosOrganizadorCargando();
}

class EventosOrganizadorExitoso extends EventosOrganizadorState {
  final List<EventModel> eventos;
  const EventosOrganizadorExitoso({required this.eventos});
}

class EventosOrganizadorError extends EventosOrganizadorState {
  final String mensaje;
  const EventosOrganizadorError({required this.mensaje});
}

// Provider para los eventos del organizador.
final eventosOrganizadorProvider =
    NotifierProvider<EventosOrganizadorNotifier, EventosOrganizadorState>(
  EventosOrganizadorNotifier.new,
);

// Notifier para manejar los eventos del organizador.
class EventosOrganizadorNotifier extends Notifier<EventosOrganizadorState> {
  late final EventoRepository _repository;

  @override
  EventosOrganizadorState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const EventosOrganizadorInicial();
  }

  // Carga los eventos del organizador.
  Future<void> cargarEventos(String idOrganizador) async {
    state = const EventosOrganizadorCargando();

    try {
      final eventos =
          await _repository.obtenerEventosPorOrganizador(idOrganizador);
      state = EventosOrganizadorExitoso(eventos: eventos);
    } catch (e) {
      state = EventosOrganizadorError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Agrega un evento a la lista (después de crearlo).
  void agregarEvento(EventModel evento) {
    final estadoActual = state;
    if (estadoActual is EventosOrganizadorExitoso) {
      state = EventosOrganizadorExitoso(
        eventos: [evento, ...estadoActual.eventos],
      );
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const EventosOrganizadorInicial();
  }
}
