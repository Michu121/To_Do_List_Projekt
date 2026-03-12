import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = const Uuid();

class Group {
  final String id;
  final String name;
  final Color color;

  Group({
    String? id,
    required this.name,
    required this.color,
  }) : id = id ?? uuid.v4();

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'] ?? 'Bez grupy',
      color: Color(json['color'] ?? Colors.grey.value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  Group copyWith({
    String? name,
    Color? color,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}