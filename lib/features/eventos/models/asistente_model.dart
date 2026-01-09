// Modelo que representa un asistente con su información de perfil.
class AsistenteModel {
  final int idAsistencia;
  final String idPerfil;
  final String nombre;
  final String? avatar;
  final int? asistio; // 1 = asistió, 0 = no asistió, null = no definido pues el evento es de entrada libre.

  const AsistenteModel({
    required this.idAsistencia,
    required this.idPerfil,
    required this.nombre,
    this.avatar,
    this.asistio,
  });

  factory AsistenteModel.fromMap(Map<String, dynamic> map) {
    // El perfil viene con el alias 'perfil' del query.
    final perfil = map['perfil'] as Map<String, dynamic>?;
    
    return AsistenteModel(
      idAsistencia: map['id_asistencia'] as int,
      idPerfil: map['id_perfil'] as String,
      nombre: perfil?['nombre'] as String? ?? 'Sin nombre',
      avatar: perfil?['avatar'] as String?,
      asistio: map['asistio'] as int?,
    );
  }

  // Estado de asistencia como texto.
  String get estadoAsistencia {
    switch (asistio) {
      case 1:
        return 'Asistió';
      case 0:
        return 'No asistió';
      default:
        return 'Pendiente';
    }
  }

  @override
  String toString() {
    return 'AsistenteModel(idAsistencia: $idAsistencia, nombre: $nombre, asistio: $asistio)';
  }
}
