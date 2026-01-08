import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class CalificacionModel {
  final int id;
  final String? idEstudiante;
  final int idEvento;
  final int calificacion;
  final String? comentario;
  final DateTime fechaCalificacion;

  CalificacionModel({
    required this.id,
    this.idEstudiante,
    required this.idEvento,
    required this.calificacion,
    this.comentario,
    required this.fechaCalificacion,
  });

  CalificacionModel copyWith({
    int? id,
    String? idEstudiante,
    int? idEvento,
    int? calificacion,
    String? comentario,
    DateTime? fechaCalificacion,
  }) {
    return CalificacionModel(
      id: id ?? this.id,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      idEvento: idEvento ?? this.idEvento,
      calificacion: calificacion ?? this.calificacion,
      comentario: comentario ?? this.comentario,
      fechaCalificacion: fechaCalificacion ?? this.fechaCalificacion,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_calificacion': id,
      'id_perfil': idEstudiante,
      'id_evento': idEvento,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': fechaCalificacion.millisecondsSinceEpoch,
    };
  }

  factory CalificacionModel.fromMap(Map<String, dynamic> map) {
    // Parsea la fecha desde string ISO 8601 y la convierte a hora local.
    DateTime parsearFecha(dynamic valor) {
      if (valor == null) return DateTime.now();
      if (valor is DateTime) return valor.toLocal();
      if (valor is String) return DateTime.parse(valor).toLocal();
      if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
      return DateTime.now();
    }

    return CalificacionModel(
      id: map['id_calificacion'] as int,
      idEstudiante: map['id_perfil'] != null ? map['id_perfil'] as String : null,
      idEvento: map['id_evento'] as int,
      calificacion: map['calificacion'] as int,
      comentario: map['comentario'] != null ? map['comentario'] as String : null,
      fechaCalificacion: parsearFecha(map['fecha']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CalificacionModel.fromJson(String source) => CalificacionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CalificacionModel(id: $id, idEstudiante: $idEstudiante, idEvento: $idEvento, calificacion: $calificacion, comentario: $comentario, fechaCalificacion: $fechaCalificacion)';
  }

  @override
  bool operator ==(covariant CalificacionModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.idEstudiante == idEstudiante &&
      other.idEvento == idEvento &&
      other.calificacion == calificacion &&
      other.comentario == comentario &&
      other.fechaCalificacion == fechaCalificacion;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      idEstudiante.hashCode ^
      idEvento.hashCode ^
      calificacion.hashCode ^
      comentario.hashCode ^
      fechaCalificacion.hashCode;
  }
}
