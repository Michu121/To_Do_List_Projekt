import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

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
      name: json['name'],
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