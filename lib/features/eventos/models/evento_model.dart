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

  // Convierte el modelo a un mapa para insertar en Supabase.
  Map<String, dynamic> toMapParaInsertar() {
    return <String, dynamic>{
      'id_organizador': idOrganizador,
      'nombre': nombre,
      'fecha': fecha.toIso8601String(),
      'entrada_libre': entradaLibre,
      'descripcion': descripcion,
      'validado': validado,
      'imagen': imageUrl,
      'lugar': lugar,
      'flyer': flyer,
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_evento': id,
      'id_organizador': idOrganizador,
      'nombre': nombre,
      'fecha': fecha.toIso8601String(),
      'fecha_publicado': fechaPublicado?.toIso8601String(),
      'created_at': fechaCreacion.toIso8601String(),
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
    // Parsea la fecha desde string ISO 8601.
    DateTime parsearFecha(dynamic valor) {
      if (valor == null) return DateTime.now();
      if (valor is DateTime) return valor;
      if (valor is String) return DateTime.parse(valor);
      return DateTime.now();
    }

    DateTime? parsearFechaOpcional(dynamic valor) {
      if (valor == null) return null;
      if (valor is DateTime) return valor;
      if (valor is String) return DateTime.parse(valor);
      return null;
    }

    return EventModel(
      id: map['id_evento'] as int,
      idOrganizador: map['id_organizador'] as String,
      nombre: map['nombre'] as String,
      fecha: parsearFecha(map['fecha']),
      fechaPublicado: parsearFechaOpcional(map['fecha_publicado']),
      fechaCreacion: parsearFecha(map['created_at']),
      entradaLibre: map['entrada_libre'] as bool,
      descripcion: map['descripcion'] as String?,
      validado: map['validado'] as bool,
      imageUrl: map['imagen'] as String?,
      lugar: map['lugar'] as String,
      flyer: map['flyer'] as String?,
      resumenComentarios: map['resumen_comentarios'] as String?,
      categorias: map['categorias'] != null
          ? (map['categorias'] as List)
              .map((x) => CategoriaModel.fromMap(x as Map<String, dynamic>))
              .toList()
          : [],
      asistencias: map['asistencias'] != null
          ? (map['asistencias'] as List)
              .map((x) => AsistenciaModel.fromMap(x as Map<String, dynamic>))
              .toList()
          : null,
      calificaciones: map['calificaciones'] != null
          ? (map['calificaciones'] as List)
              .map((x) => CalificacionModel.fromMap(x as Map<String, dynamic>))
              .toList()
          : null,
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
