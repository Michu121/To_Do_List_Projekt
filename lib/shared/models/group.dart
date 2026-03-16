import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Group {
  final String id;
  final String name;
  final Color color;
  final List<String> memberUids;

  Group({
    String? id,
    required this.name,
    required this.color,
    List<String>? memberUids,
  })  : id = id ?? uuid.v4(),
        memberUids = memberUids ?? [];

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      memberUids: List<String>.from(json['memberUids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'memberUids': memberUids,
    };
  }

  Group copyWith({
    String? name,
    Color? color,
    List<String>? memberUids,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      memberUids: memberUids ?? this.memberUids,
    );
  }
}