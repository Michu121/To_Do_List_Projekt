import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = const Uuid();

class Category {
  final String id;
  final String name;
  final Color color;

  Category({
    String? id,
    required this.name,
    required this.color,
  }) : id = id ?? uuid.v4();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? 'Bez nazwy',
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

  Category copyWith({
    String? name,
    Color? color,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}