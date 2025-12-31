// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:escomevents_app/features/eventos/models/asistencia_model.dart';
import 'package:escomevents_app/features/eventos/models/calificacion_model.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';

class EventModel {
  final int id;
  final String idOrganizador;
  final String nombre;
  final DateTime fecha;
  final DateTime? fechaPublicado;
  final DateTime fechaCreacion;
  final bool entradaLibre;
  final String? descripcion;
  final bool validado;
  final String? imageUrl;
  final String lugar;
  final String? flyer; // URL o path del flyer
  final String? resumenComentarios;
  final List<CategoriaModel> categorias;
  final List<AsistenciaModel>? asistencias;
  final List<CalificacionModel>? calificaciones;
  
  EventModel({
    required this.id,
    required this.idOrganizador,
    required this.nombre,
    required this.fecha,
    this.fechaPublicado,
    required this.fechaCreacion,
    required this.entradaLibre,
    this.descripcion,
    required this.validado,
    this.imageUrl,
    required this.lugar,
    this.flyer,
    this.resumenComentarios,
    required this.categorias,
    this.asistencias,
    this.calificaciones,
  });


  EventModel copyWith({
    int? id,
    String? idOrganizador,
    String? nombre,
    DateTime? fecha,
    DateTime? fechaPublicado,
    DateTime? fechaCreacion,
    bool? entradaLibre,
    String? descripcion,
    bool? validado,
    String? imageUrl,
    String? lugar,
    String? flyer,
    String? resumenComentarios,
    List<CategoriaModel>? categorias,
    List<AsistenciaModel>? asistencias,
    List<CalificacionModel>? calificaciones,
  }) {
    return EventModel(
      id: id ?? this.id,
      idOrganizador: idOrganizador ?? this.idOrganizador,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      fechaPublicado: fechaPublicado ?? this.fechaPublicado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      entradaLibre: entradaLibre ?? this.entradaLibre,
      descripcion: descripcion ?? this.descripcion,
      validado: validado ?? this.validado,
      imageUrl: imageUrl ?? this.imageUrl,
      lugar: lugar ?? this.lugar,
      flyer: flyer ?? this.flyer,
      resumenComentarios: resumenComentarios ?? this.resumenComentarios,
      categorias: categorias ?? this.categorias,
      asistencias: asistencias ?? this.asistencias,
      calificaciones: calificaciones ?? this.calificaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_categoria': id,
      'id_organizador': idOrganizador,
      'nombre': nombre,
      'fecha': fecha.millisecondsSinceEpoch,
      'fecha_publicado': fechaPublicado?.millisecondsSinceEpoch,
      'created_at': fechaCreacion.millisecondsSinceEpoch,
      'entrada_libre': entradaLibre,
      'descripcion': descripcion,
      'validado': validado,
      'imagen': imageUrl,
      'lugar': lugar,
      'flyer': flyer,
      'resumen_comentarios': resumenComentarios,
      'categorias': categorias.map((x) => x.toMap()).toList(),
      'asistencias': asistencias?.map((x) => x.toMap()).toList(),
      'calificaciones': calificaciones?.map((x) => x.toMap()).toList(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id_categoria'] as int,
      idOrganizador: map['id_organizador'] as String,
      nombre: map['nombre'] as String,
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int),
      fechaPublicado: map['fecha_publicado'] != null ? DateTime.fromMillisecondsSinceEpoch(map['fecha_publicado'] as int) : null,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      entradaLibre: map['entrada_libre'] as bool,
      descripcion: map['descripcion'] != null ? map['descripcion'] as String : null,
      validado: map['validado'] as bool,
      imageUrl: map['imagen'] != null ? map['imagen'] as String : null,
      lugar: map['lugar'] as String,
      flyer: map['flyer'] != null ? map['flyer'] as String : null,
      resumenComentarios: map['resumen_comentarios'] != null ? map['resumen_comentarios'] as String : null,
      categorias: List<CategoriaModel>.from((map['categorias'] as List<int>).map<CategoriaModel>((x) => CategoriaModel.fromMap(x as Map<String,dynamic>),),),
      asistencias: map['asistencias'] != null ? List<AsistenciaModel>.from((map['asistencias'] as List<int>).map<AsistenciaModel?>((x) => AsistenciaModel.fromMap(x as Map<String,dynamic>),),) : null,
      calificaciones: map['calificaciones'] != null ? List<CalificacionModel>.from((map['calificaciones'] as List<int>).map<CalificacionModel?>((x) => CalificacionModel.fromMap(x as Map<String,dynamic>),),) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) => EventModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EventModel(id: $id, idOrganizador: $idOrganizador, nombre: $nombre, fecha: $fecha, fechaPublicado: $fechaPublicado, fechaCreacion: $fechaCreacion, entradaLibre: $entradaLibre, descripcion: $descripcion, validado: $validado, imageUrl: $imageUrl, lugar: $lugar, flyer: $flyer, resumenComentarios: $resumenComentarios, categorias: $categorias, asistencias: $asistencias, calificaciones: $calificaciones)';
  }

  @override
  bool operator ==(covariant EventModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.idOrganizador == idOrganizador &&
      other.nombre == nombre &&
      other.fecha == fecha &&
      other.fechaPublicado == fechaPublicado &&
      other.fechaCreacion == fechaCreacion &&
      other.entradaLibre == entradaLibre &&
      other.descripcion == descripcion &&
      other.validado == validado &&
      other.imageUrl == imageUrl &&
      other.lugar == lugar &&
      other.flyer == flyer &&
      other.resumenComentarios == resumenComentarios &&
      listEquals(other.categorias, categorias) &&
      listEquals(other.asistencias, asistencias) &&
      listEquals(other.calificaciones, calificaciones);
  }

  @override
  int get hashCode {
    return id.hashCode ^
      idOrganizador.hashCode ^
      nombre.hashCode ^
      fecha.hashCode ^
      fechaPublicado.hashCode ^
      fechaCreacion.hashCode ^
      entradaLibre.hashCode ^
      descripcion.hashCode ^
      validado.hashCode ^
      imageUrl.hashCode ^
      lugar.hashCode ^
      flyer.hashCode ^
      resumenComentarios.hashCode ^
      categorias.hashCode ^
      asistencias.hashCode ^
      calificaciones.hashCode;
  }
}
