import 'package:escomevents_app/features/home/views/pages/bienvenida_page.dart';

//Modelo que representa el perfil de un usuario.
class PerfilModel {
  //Identificador único del perfil (UUID).
  final String idPerfil;

  //Nombre del usuario.
  final String nombre;

  //URL del avatar del usuario.
  final String? avatar;

  //URL del código QR del usuario.
  final String? urlQr;

  //Rol del usuario en la aplicación.
  final RolUsuario rol;

  //Indica si el usuario necesita confirmar su correo electrónico.
  final bool requiereConfirmacion;

  const PerfilModel({
    required this.idPerfil,
    required this.nombre,
    this.avatar,
    this.urlQr,
    required this.rol,
    this.requiereConfirmacion = false,
  });

  //Crea un [PerfilModel] desde un mapa JSON.
  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      idPerfil: json['id_perfil'] as String,
      nombre: json['nombre'] as String,
      avatar: json['avatar'] as String?,
      urlQr: json['url_qr'] as String?,
      rol: _parseRol(json['rol'] as String),
    );
  }

  //Convierte el modelo a un mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_perfil': idPerfil,
      'nombre': nombre,
      'avatar': avatar,
      'url_qr': urlQr,
      'rol': rol.name,
    };
  }

  //Parsea el rol desde un string.
  static RolUsuario _parseRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'organizador':
        return RolUsuario.organizador;
      case 'administrador':
        return RolUsuario.administrador;
      case 'estudiante':
      default:
        return RolUsuario.estudiante;
    }
  }

  //Crea una copia del modelo con los valores especificados.
  PerfilModel copyWith({
    String? idPerfil,
    String? nombre,
    String? avatar,
    String? urlQr,
    RolUsuario? rol,
    bool? requiereConfirmacion,
  }) {
    return PerfilModel(
      idPerfil: idPerfil ?? this.idPerfil,
      nombre: nombre ?? this.nombre,
      avatar: avatar ?? this.avatar,
      urlQr: urlQr ?? this.urlQr,
      rol: rol ?? this.rol,
      requiereConfirmacion: requiereConfirmacion ?? this.requiereConfirmacion,
    );
  }
}
