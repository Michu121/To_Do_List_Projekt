import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Group {
  final String id;
  final String name;
  final Color color;
  final List<String> members;
  final String createdBy;

  Group({
    String? id,
    required this.name,
    required this.color,
    List<String>? members,
    String? createdBy,
  })  : id = id ?? _uuid.v4(),
        members = members ?? [],
        createdBy = createdBy ?? '';

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Group',
      color: Color((json['color'] as num).toInt()),
      members: List<String>.from((json['members'] as List?) ?? []),
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'members': members,
      'createdBy': createdBy,
    };
  }

  @override
  bool operator ==(Object other) => other is Group && other.id == id;

  @override
  int get hashCode => id.hashCode;
}