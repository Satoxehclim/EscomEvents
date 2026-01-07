// Estados posibles para filtrar eventos.
enum FiltroEstado {
  todos,
  proximos,
  pasados,
  pendientes,
  enCorreccion,
  aprobados,
}

// Opciones de ordenamiento para eventos.
enum OrdenEvento {
  masRecientes,
  masAntiguos,
  masProximos,
  masLejanos,
}

// Filtros para consultar eventos.
class FiltroEventos {
  final FiltroEstado estado;
  final int? idCategoria;
  final OrdenEvento orden;

  const FiltroEventos({
    this.estado = FiltroEstado.todos,
    this.idCategoria,
    this.orden = OrdenEvento.masRecientes,
  });

  FiltroEventos copyWith({
    FiltroEstado? estado,
    int? idCategoria,
    OrdenEvento? orden,
    bool limpiarCategoria = false,
  }) {
    return FiltroEventos(
      estado: estado ?? this.estado,
      idCategoria: limpiarCategoria ? null : (idCategoria ?? this.idCategoria),
      orden: orden ?? this.orden,
    );
  }

  // Retorna filtros por defecto.
  static const FiltroEventos porDefecto = FiltroEventos();

  // Limpia los filtros a valores por defecto.
  FiltroEventos limpiar() => porDefecto;
}

// Obtiene el nombre legible del filtro de estado.
String obtenerNombreFiltroEstado(FiltroEstado filtro) {
  switch (filtro) {
    case FiltroEstado.todos:
      return 'Todos';
    case FiltroEstado.proximos:
      return 'Próximos';
    case FiltroEstado.pasados:
      return 'Pasados';
    case FiltroEstado.pendientes:
      return 'Pendientes';
    case FiltroEstado.enCorreccion:
      return 'En Corrección';
    case FiltroEstado.aprobados:
      return 'Aprobados';
  }
}

// Obtiene el nombre legible del orden.
String obtenerNombreOrden(OrdenEvento orden) {
  switch (orden) {
    case OrdenEvento.masRecientes:
      return 'Más recientes';
    case OrdenEvento.masAntiguos:
      return 'Más antiguos';
    case OrdenEvento.masProximos:
      return 'Más próximos';
    case OrdenEvento.masLejanos:
      return 'Más lejanos';
  }
}
