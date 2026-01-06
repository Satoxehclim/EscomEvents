import 'dart:io';

import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
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

// Estado para la edición de eventos.
sealed class EditarEventoState {
  const EditarEventoState();
}

class EditarEventoInicial extends EditarEventoState {
  const EditarEventoInicial();
}

class EditarEventoCargando extends EditarEventoState {
  const EditarEventoCargando();
}

class EditarEventoExitoso extends EditarEventoState {
  final EventModel evento;
  const EditarEventoExitoso({required this.evento});
}

class EditarEventoError extends EditarEventoState {
  final String mensaje;
  const EditarEventoError({required this.mensaje});
}

// Provider para editar eventos.
final editarEventoProvider =
    NotifierProvider<EditarEventoNotifier, EditarEventoState>(
  EditarEventoNotifier.new,
);

// Notifier para manejar la edición de eventos.
class EditarEventoNotifier extends Notifier<EditarEventoState> {
  late final EventoRepository _repository;

  @override
  EditarEventoState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const EditarEventoInicial();
  }

  // Actualiza un evento existente.
  Future<EventModel?> actualizarEvento({
    required EventModel eventoOriginal,
    required String nombre,
    required DateTime fecha,
    required String lugar,
    required bool entradaLibre,
    String? descripcion,
    File? nuevaImagen,
    File? nuevoFlyer,
    required bool eliminarImagen,
    required bool eliminarFlyer,
    required List<CategoriaModel> categorias,
  }) async {
    state = const EditarEventoCargando();

    try {
      final eventoActualizado = await _repository.actualizarEvento(
        eventoOriginal: eventoOriginal,
        nombre: nombre,
        fecha: fecha,
        lugar: lugar,
        entradaLibre: entradaLibre,
        descripcion: descripcion,
        nuevaImagen: nuevaImagen,
        nuevoFlyer: nuevoFlyer,
        eliminarImagen: eliminarImagen,
        eliminarFlyer: eliminarFlyer,
        categorias: categorias,
      );

      state = EditarEventoExitoso(evento: eventoActualizado);
      return eventoActualizado;
    } catch (e) {
      state = EditarEventoError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const EditarEventoInicial();
  }
}

// Estado para eliminar eventos.
sealed class EliminarEventoState {
  const EliminarEventoState();
}

class EliminarEventoInicial extends EliminarEventoState {
  const EliminarEventoInicial();
}

class EliminarEventoCargando extends EliminarEventoState {
  const EliminarEventoCargando();
}

class EliminarEventoExitoso extends EliminarEventoState {
  const EliminarEventoExitoso();
}

class EliminarEventoError extends EliminarEventoState {
  final String mensaje;
  const EliminarEventoError({required this.mensaje});
}

// Provider para eliminar eventos.
final eliminarEventoProvider =
    NotifierProvider<EliminarEventoNotifier, EliminarEventoState>(
  EliminarEventoNotifier.new,
);

// Notifier para manejar la eliminación de eventos.
class EliminarEventoNotifier extends Notifier<EliminarEventoState> {
  late final EventoRepository _repository;

  @override
  EliminarEventoState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const EliminarEventoInicial();
  }

  // Elimina un evento.
  Future<bool> eliminarEvento(EventModel evento) async {
    state = const EliminarEventoCargando();

    try {
      await _repository.eliminarEvento(evento);
      state = const EliminarEventoExitoso();
      return true;
    } catch (e) {
      state = EliminarEventoError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    state = const EliminarEventoInicial();
  }
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

// Estado para la lista de eventos del organizador con paginación.
sealed class EventosOrganizadorState {
  const EventosOrganizadorState();
}

class EventosOrganizadorInicial extends EventosOrganizadorState {
  const EventosOrganizadorInicial();
}

class EventosOrganizadorCargando extends EventosOrganizadorState {
  // Eventos existentes mientras se carga más.
  final List<EventModel> eventosAnteriores;
  const EventosOrganizadorCargando({this.eventosAnteriores = const []});
}

class EventosOrganizadorExitoso extends EventosOrganizadorState {
  final List<EventModel> eventos;
  final bool hayMas;
  final int paginaActual;
  final bool cargandoMas;

  const EventosOrganizadorExitoso({
    required this.eventos,
    this.hayMas = false,
    this.paginaActual = 0,
    this.cargandoMas = false,
  });

  EventosOrganizadorExitoso copyWith({
    List<EventModel>? eventos,
    bool? hayMas,
    int? paginaActual,
    bool? cargandoMas,
  }) {
    return EventosOrganizadorExitoso(
      eventos: eventos ?? this.eventos,
      hayMas: hayMas ?? this.hayMas,
      paginaActual: paginaActual ?? this.paginaActual,
      cargandoMas: cargandoMas ?? this.cargandoMas,
    );
  }
}

class EventosOrganizadorError extends EventosOrganizadorState {
  final String mensaje;
  final List<EventModel> eventosAnteriores;

  const EventosOrganizadorError({
    required this.mensaje,
    this.eventosAnteriores = const [],
  });
}

// Provider para los eventos del organizador.
final eventosOrganizadorProvider =
    NotifierProvider<EventosOrganizadorNotifier, EventosOrganizadorState>(
  EventosOrganizadorNotifier.new,
);

// Notifier para manejar los eventos del organizador con paginación.
class EventosOrganizadorNotifier extends Notifier<EventosOrganizadorState> {
  late final EventoRepository _repository;
  static const int _tamanoPagina = 10;
  String? _idOrganizadorActual;
  FiltroEventos? _filtrosActuales;

  @override
  EventosOrganizadorState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const EventosOrganizadorInicial();
  }

  // Carga la primera página de eventos.
  Future<void> cargarEventos(
    String idOrganizador, {
    FiltroEventos? filtros,
  }) async {
    _idOrganizadorActual = idOrganizador;
    _filtrosActuales = filtros;
    state = const EventosOrganizadorCargando();

    try {
      final resultado = await _repository.obtenerEventosPorOrganizador(
        idOrganizador,
        pagina: 0,
        tamanoPagina: _tamanoPagina,
        filtros: filtros,
      );

      state = EventosOrganizadorExitoso(
        eventos: resultado.datos,
        hayMas: resultado.hayMas,
        paginaActual: 0,
      );
    } catch (e) {
      state = EventosOrganizadorError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Carga más eventos (siguiente página).
  Future<void> cargarMasEventos() async {
    final estadoActual = state;
    if (estadoActual is! EventosOrganizadorExitoso) return;
    if (!estadoActual.hayMas || estadoActual.cargandoMas) return;
    if (_idOrganizadorActual == null) return;

    // Marca que está cargando más.
    state = estadoActual.copyWith(cargandoMas: true);

    try {
      final siguientePagina = estadoActual.paginaActual + 1;
      final resultado = await _repository.obtenerEventosPorOrganizador(
        _idOrganizadorActual!,
        pagina: siguientePagina,
        tamanoPagina: _tamanoPagina,
        filtros: _filtrosActuales,
      );

      state = EventosOrganizadorExitoso(
        eventos: [...estadoActual.eventos, ...resultado.datos],
        hayMas: resultado.hayMas,
        paginaActual: siguientePagina,
        cargandoMas: false,
      );
    } catch (e) {
      // Mantiene los eventos existentes pero muestra error.
      state = EventosOrganizadorError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
        eventosAnteriores: estadoActual.eventos,
      );
    }
  }

  // Recarga todos los eventos desde la primera página con los mismos filtros.
  Future<void> recargarEventos() async {
    if (_idOrganizadorActual != null) {
      await cargarEventos(_idOrganizadorActual!, filtros: _filtrosActuales);
    }
  }

  // Aplica nuevos filtros y recarga.
  Future<void> aplicarFiltros(FiltroEventos? filtros) async {
    if (_idOrganizadorActual != null) {
      await cargarEventos(_idOrganizadorActual!, filtros: filtros);
    }
  }

  // Agrega un evento a la lista (después de crearlo).
  void agregarEvento(EventModel evento) {
    final estadoActual = state;
    if (estadoActual is EventosOrganizadorExitoso) {
      state = estadoActual.copyWith(
        eventos: [evento, ...estadoActual.eventos],
      );
    }
  }

  // Actualiza un evento en la lista.
  void actualizarEvento(EventModel eventoActualizado) {
    final estadoActual = state;
    if (estadoActual is EventosOrganizadorExitoso) {
      final eventosActualizados = estadoActual.eventos.map((evento) {
        if (evento.id == eventoActualizado.id) {
          return eventoActualizado;
        }
        return evento;
      }).toList();

      state = estadoActual.copyWith(eventos: eventosActualizados);
    }
  }

  // Elimina un evento de la lista.
  void eliminarEvento(int idEvento) {
    final estadoActual = state;
    if (estadoActual is EventosOrganizadorExitoso) {
      final eventosActualizados = estadoActual.eventos
          .where((evento) => evento.id != idEvento)
          .toList();

      state = estadoActual.copyWith(eventos: eventosActualizados);
    }
  }

  // Reinicia el estado.
  void reiniciar() {
    _idOrganizadorActual = null;
    _filtrosActuales = null;
    state = const EventosOrganizadorInicial();
  }
}

// Estado para la lista de eventos públicos con paginación.
sealed class EventosPublicosState {
  const EventosPublicosState();
}

class EventosPublicosInicial extends EventosPublicosState {
  const EventosPublicosInicial();
}

class EventosPublicosCargando extends EventosPublicosState {
  final List<EventModel> eventosAnteriores;
  const EventosPublicosCargando({this.eventosAnteriores = const []});
}

class EventosPublicosExitoso extends EventosPublicosState {
  final List<EventModel> eventos;
  final bool hayMas;
  final int paginaActual;
  final bool cargandoMas;

  const EventosPublicosExitoso({
    required this.eventos,
    this.hayMas = false,
    this.paginaActual = 0,
    this.cargandoMas = false,
  });

  EventosPublicosExitoso copyWith({
    List<EventModel>? eventos,
    bool? hayMas,
    int? paginaActual,
    bool? cargandoMas,
  }) {
    return EventosPublicosExitoso(
      eventos: eventos ?? this.eventos,
      hayMas: hayMas ?? this.hayMas,
      paginaActual: paginaActual ?? this.paginaActual,
      cargandoMas: cargandoMas ?? this.cargandoMas,
    );
  }
}

class EventosPublicosError extends EventosPublicosState {
  final String mensaje;
  final List<EventModel> eventosAnteriores;

  const EventosPublicosError({
    required this.mensaje,
    this.eventosAnteriores = const [],
  });
}

// Provider para los eventos públicos.
final eventosPublicosProvider =
    NotifierProvider<EventosPublicosNotifier, EventosPublicosState>(
  EventosPublicosNotifier.new,
);

// Notifier para manejar la lista de eventos públicos.
class EventosPublicosNotifier extends Notifier<EventosPublicosState> {
  late final EventoRepository _repository;
  FiltroEventos? _filtrosActuales;

  @override
  EventosPublicosState build() {
    _repository = ref.watch(eventoRepositoryProvider);
    return const EventosPublicosInicial();
  }

  // Carga los eventos públicos.
  Future<void> cargarEventos({FiltroEventos? filtros}) async {
    _filtrosActuales = filtros;

    // Mantiene los eventos anteriores mientras carga.
    final eventosAnteriores = switch (state) {
      EventosPublicosExitoso(eventos: final e) => e,
      EventosPublicosCargando(eventosAnteriores: final e) => e,
      EventosPublicosError(eventosAnteriores: final e) => e,
      _ => <EventModel>[],
    };

    state = EventosPublicosCargando(eventosAnteriores: eventosAnteriores);

    try {
      final resultado = await _repository.obtenerEventosPublicos(
        pagina: 0,
        filtros: filtros,
      );

      state = EventosPublicosExitoso(
        eventos: resultado.datos,
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
      );
    } catch (e) {
      state = EventosPublicosError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
        eventosAnteriores: eventosAnteriores,
      );
    }
  }

  // Carga más eventos (paginación).
  Future<void> cargarMasEventos() async {
    final estadoActual = state;

    // Solo carga más si está en estado exitoso y hay más eventos.
    if (estadoActual is! EventosPublicosExitoso ||
        !estadoActual.hayMas ||
        estadoActual.cargandoMas) {
      return;
    }

    state = estadoActual.copyWith(cargandoMas: true);

    try {
      final resultado = await _repository.obtenerEventosPublicos(
        pagina: estadoActual.paginaActual + 1,
        filtros: _filtrosActuales,
      );

      state = EventosPublicosExitoso(
        eventos: [...estadoActual.eventos, ...resultado.datos],
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
        cargandoMas: false,
      );
    } catch (e) {
      // Si falla, vuelve al estado anterior sin el indicador de carga.
      state = estadoActual.copyWith(cargandoMas: false);
    }
  }

  // Recarga los eventos.
  Future<void> recargar() async {
    await cargarEventos(filtros: _filtrosActuales);
  }

  // Aplica nuevos filtros y recarga.
  Future<void> aplicarFiltros(FiltroEventos? filtros) async {
    await cargarEventos(filtros: filtros);
  }

  // Reinicia el estado.
  void reiniciar() {
    _filtrosActuales = null;
    state = const EventosPublicosInicial();
  }
}