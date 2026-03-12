import 'package:flutter/material.dart';
enum Status {
  todo(status: 0, color: Colors.grey, icon: Icons.check_box_outline_blank),
  inProgress(status: 1, color: Colors.blue, icon: Icons.check_box),
  done(status: 2, color: Colors.green, icon: Icons.check);

  final int status;
  final Color color;
  final IconData icon;

  const Status({
    required this.status,
    required this.color,
    required this.icon,
});
}