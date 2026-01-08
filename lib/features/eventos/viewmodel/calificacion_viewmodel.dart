import 'package:escomevents_app/features/eventos/models/calificacion_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_calificaciones_model.dart';
import 'package:escomevents_app/features/eventos/repositories/calificacion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de calificaciones.
final calificacionRepositoryProvider = Provider<CalificacionRepository>((ref) {
  return CalificacionRepositoryImpl();
});

// Estado para la lista de calificaciones.
sealed class CalificacionesEventoState {
  const CalificacionesEventoState();
}

class CalificacionesEventoInicial extends CalificacionesEventoState {
  const CalificacionesEventoInicial();
}

class CalificacionesEventoCargando extends CalificacionesEventoState {
  const CalificacionesEventoCargando();
}

class CalificacionesEventoCargado extends CalificacionesEventoState {
  final List<CalificacionModel> calificaciones;
  final bool hayMas;
  final int paginaActual;
  final int totalCalificaciones;
  final double promedioCalificaciones;
  final FiltroCalificaciones filtro;
  final bool cargandoMas;

  const CalificacionesEventoCargado({
    required this.calificaciones,
    required this.hayMas,
    required this.paginaActual,
    required this.totalCalificaciones,
    required this.promedioCalificaciones,
    required this.filtro,
    this.cargandoMas = false,
  });

  CalificacionesEventoCargado copyWith({
    List<CalificacionModel>? calificaciones,
    bool? hayMas,
    int? paginaActual,
    int? totalCalificaciones,
    double? promedioCalificaciones,
    FiltroCalificaciones? filtro,
    bool? cargandoMas,
  }) {
    return CalificacionesEventoCargado(
      calificaciones: calificaciones ?? this.calificaciones,
      hayMas: hayMas ?? this.hayMas,
      paginaActual: paginaActual ?? this.paginaActual,
      totalCalificaciones: totalCalificaciones ?? this.totalCalificaciones,
      promedioCalificaciones:
          promedioCalificaciones ?? this.promedioCalificaciones,
      filtro: filtro ?? this.filtro,
      cargandoMas: cargandoMas ?? this.cargandoMas,
    );
  }
}

class CalificacionesEventoError extends CalificacionesEventoState {
  final String mensaje;

  const CalificacionesEventoError({required this.mensaje});
}

// Provider para las calificaciones de un evento.
final calificacionesEventoProvider =
    NotifierProvider<CalificacionesEventoNotifier, CalificacionesEventoState>(
  CalificacionesEventoNotifier.new,
);

// Notifier para manejar las calificaciones de un evento.
class CalificacionesEventoNotifier extends Notifier<CalificacionesEventoState> {
  late final CalificacionRepository _repository;
  static const int _tamanoPagina = 10;
  int? _idEventoActual;
  FiltroCalificaciones? _filtroActual;

  @override
  CalificacionesEventoState build() {
    _repository = ref.watch(calificacionRepositoryProvider);
    return const CalificacionesEventoInicial();
  }

  // Carga las calificaciones del evento.
  Future<void> cargarCalificaciones({
    required int idEvento,
    FiltroCalificaciones? filtro,
  }) async {
    _idEventoActual = idEvento;
    _filtroActual = filtro ?? const FiltroCalificaciones();
    state = const CalificacionesEventoCargando();

    try {
      final resultado = await _repository.obtenerCalificacionesEvento(
        idEvento: idEvento,
        pagina: 0,
        tamanoPagina: _tamanoPagina,
        filtro: _filtroActual,
      );

      state = CalificacionesEventoCargado(
        calificaciones: resultado.calificaciones,
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
        totalCalificaciones: resultado.totalCalificaciones,
        promedioCalificaciones: resultado.promedioCalificaciones,
        filtro: _filtroActual!,
      );
    } catch (e) {
      state = CalificacionesEventoError(
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Carga más calificaciones (paginación).
  Future<void> cargarMas() async {
    final estadoActual = state;
    if (estadoActual is! CalificacionesEventoCargado) return;
    if (!estadoActual.hayMas || estadoActual.cargandoMas) return;
    if (_idEventoActual == null) return;

    state = estadoActual.copyWith(cargandoMas: true);

    try {
      final resultado = await _repository.obtenerCalificacionesEvento(
        idEvento: _idEventoActual!,
        pagina: estadoActual.paginaActual + 1,
        tamanoPagina: _tamanoPagina,
        filtro: _filtroActual,
      );

      state = CalificacionesEventoCargado(
        calificaciones: [
          ...estadoActual.calificaciones,
          ...resultado.calificaciones,
        ],
        hayMas: resultado.hayMas,
        paginaActual: resultado.paginaActual,
        totalCalificaciones: resultado.totalCalificaciones,
        promedioCalificaciones: resultado.promedioCalificaciones,
        filtro: estadoActual.filtro,
      );
    } catch (_) {
      // Restaura el estado anterior en caso de error.
      state = estadoActual.copyWith(cargandoMas: false);
    }
  }

  // Cambia el filtro y recarga.
  Future<void> cambiarFiltro(FiltroCalificaciones nuevoFiltro) async {
    if (_idEventoActual == null) return;
    await cargarCalificaciones(
      idEvento: _idEventoActual!,
      filtro: nuevoFiltro,
    );
  }

  // Reinicia el estado.
  void reiniciar() {
    _idEventoActual = null;
    _filtroActual = null;
    state = const CalificacionesEventoInicial();
  }
}
