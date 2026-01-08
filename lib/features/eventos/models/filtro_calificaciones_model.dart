// Tipo de ordenamiento para calificaciones.
enum OrdenCalificacion {
  calificacionAsc,
  calificacionDesc,
  fechaAsc,
  fechaDesc,
}

// Modelo de filtro para obtener calificaciones.
class FiltroCalificaciones {
  final OrdenCalificacion orden;

  const FiltroCalificaciones({
    this.orden = OrdenCalificacion.fechaDesc,
  });

  // Obtiene el campo de ordenamiento para la query.
  String get campoOrden {
    switch (orden) {
      case OrdenCalificacion.calificacionAsc:
      case OrdenCalificacion.calificacionDesc:
        return 'calificacion';
      case OrdenCalificacion.fechaAsc:
      case OrdenCalificacion.fechaDesc:
        return 'fecha';
    }
  }

  // Indica si el ordenamiento es ascendente.
  bool get esAscendente {
    switch (orden) {
      case OrdenCalificacion.calificacionAsc:
      case OrdenCalificacion.fechaAsc:
        return true;
      case OrdenCalificacion.calificacionDesc:
      case OrdenCalificacion.fechaDesc:
        return false;
    }
  }

  // Crea una copia con nuevos valores.
  FiltroCalificaciones copyWith({OrdenCalificacion? orden}) {
    return FiltroCalificaciones(orden: orden ?? this.orden);
  }

  // Obtiene el texto descriptivo del filtro actual.
  String get textoOrden {
    switch (orden) {
      case OrdenCalificacion.calificacionAsc:
        return 'Calificación (menor a mayor)';
      case OrdenCalificacion.calificacionDesc:
        return 'Calificación (mayor a menor)';
      case OrdenCalificacion.fechaAsc:
        return 'Fecha (más antiguas)';
      case OrdenCalificacion.fechaDesc:
        return 'Fecha (más recientes)';
    }
  }
}
