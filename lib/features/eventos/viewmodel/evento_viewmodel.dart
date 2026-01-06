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

  // Reinicia el estado.
  void reiniciar() {
    _idOrganizadorActual = null;
    _filtrosActuales = null;
    state = const EventosOrganizadorInicial();
  }
}