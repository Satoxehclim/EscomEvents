import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class AsistenciaModel {
  final int id;
  final String? idEstudiante;
  final int idEvento;
  final int? asistio; // 1 para asistió, 0 para no asistió y null para no se requeria registrar asistencia

  AsistenciaModel({
    required this.id,
    this.idEstudiante,
    required this.idEvento,
    this.asistio,
  });


  AsistenciaModel copyWith({
    int? id,
    String? idEstudiante,
    int? idEvento,
    int? asistio,
  }) {
    return AsistenciaModel(
      id: id ?? this.id,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      idEvento: idEvento ?? this.idEvento,
      asistio: asistio ?? this.asistio,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_asistencia': id,
      'id_perfil': idEstudiante,
      'id_evento': idEvento,
      'asistio': asistio,
    };
  }

  factory AsistenciaModel.fromMap(Map<String, dynamic> map) {
    return AsistenciaModel(
      id: map['id_asistencia'] as int,
      idEstudiante: map['id_perfil'] != null ? map['id_perfil'] as String : null,
      idEvento: map['id_evento'] as int,
      asistio: map['asistio'] != null ? map['asistio'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AsistenciaModel.fromJson(String source) => AsistenciaModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AsistenciaModel(id: $id, idEstudiante: $idEstudiante, idEvento: $idEvento, asistio: $asistio)';
  }

  @override
  bool operator ==(covariant AsistenciaModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.idEstudiante == idEstudiante &&
      other.idEvento == idEvento &&
      other.asistio == asistio;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      idEstudiante.hashCode ^
      idEvento.hashCode ^
      asistio.hashCode;
  }
}
