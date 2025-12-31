// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

class CategoriaModel {
  final int id;
  final String nombre;
  final IconData? icono;
  final String? descripcion;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.icono,
    this.descripcion,
  });

  CategoriaModel copyWith({
    int? id,
    String? nombre,
    IconData? icono,
    String? descripcion,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_categoria': id,
      'nombre': nombre,
      'icono': icono?.codePoint,
      'descripcion': descripcion,
    };
  }

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    final nombreCategoria = map['nombre'] as String;
    return CategoriaModel(
      id: map['id_categoria'] as int,
      nombre: nombreCategoria,
      icono: _asignarIconoPorNombre(nombreCategoria),
      descripcion: map['descripcion'] != null ? map['descripcion'] as String : null,
    );
  }

  /// Función auxiliar para mapear texto a Iconos de Flutter
  static IconData _asignarIconoPorNombre(String nombre) {
    // Normalizamos el texto a minúsculas y quitamos espacios
    final nombreNormalizado = nombre.toLowerCase().trim();

    // Verificamos palabras clave (contains) para ser más flexibles
    if (nombreNormalizado.contains('académico') || nombreNormalizado.contains('academico')) {
      return Icons.school; // RF-007, Público objetivo Estudiantes
    } else if (nombreNormalizado.contains('cultural')) {
      return Icons.theater_comedy; // RF-007
    } else if (nombreNormalizado.contains('deportivo') || nombreNormalizado.contains('deporte')) {
      return Icons.sports_soccer; // RF-007
    } else if (nombreNormalizado.contains('tecnología') || nombreNormalizado.contains('hackathon')) {
      return Icons.computer; // Sugerido para ESCOM
    } else if (nombreNormalizado.contains('institucional')) {
      return Icons.account_balance; // Sugerido para Administrativos
    } else if (nombreNormalizado.contains('taller') || nombreNormalizado.contains('curso')) {
      return Icons.build;
    } else if (nombreNormalizado.contains('empleo') || nombreNormalizado.contains('reclutamiento')) {
      return Icons.work;
    }
    
    // Ícono por defecto si no encuentra coincidencia
    return Icons.event_note; 
  }

  String toJson() => json.encode(toMap());

  factory CategoriaModel.fromJson(String source) => CategoriaModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CategoriaModel(id: $id, nombre: $nombre, icono: $icono, descripcion: $descripcion)';
  }

  @override
  bool operator ==(covariant CategoriaModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.nombre == nombre &&
      other.icono == icono &&
      other.descripcion == descripcion;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      nombre.hashCode ^
      icono.hashCode ^
      descripcion.hashCode;
  }
}
