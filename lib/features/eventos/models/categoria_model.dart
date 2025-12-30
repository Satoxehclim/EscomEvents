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
    return CategoriaModel(
      id: map['id_categoria'] as int,
      nombre: map['nombre'] as String,
      icono: map['icono'] != null ? IconData(map['icono'] as int, fontFamily: 'MaterialIcons') : null,
      descripcion: map['descripcion'] != null ? map['descripcion'] as String : null,
    );
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
