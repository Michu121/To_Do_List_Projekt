import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

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
      name: json['name'] ?? "Category",
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {

    return {
      "id": id,
      "name": name,
      "color": color.value
    };
  }
}