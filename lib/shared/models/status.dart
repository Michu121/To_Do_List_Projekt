import 'package:flutter/material.dart';

enum Status {

  todo(
    status: 0,
    color: Colors.grey,
    icon: Icons.check_box_outline_blank,
  ),

  inProgress(
    status: 1,
    color: Colors.blue,
    icon: Icons.access_time_filled,
  ),

  done(
    status: 2,
    color: Colors.green,
    icon: Icons.check,
  );

  final int status;
  final Color color;
  final IconData icon;

  const Status({
    required this.status,
    required this.color,
    required this.icon,
  });

  /// JSON → Status
  static Status fromInt(int value) {
    return Status.values.firstWhere(
          (e) => e.status == value,
      orElse: () => Status.todo,
    );
  }

  /// Status → JSON
  int toInt() {
    return status;
  }

}extension StatusName on Status {

  String get label {
    switch (this) {
      case Status.todo:
        return "Do zrobienia";

      case Status.inProgress:
        return "W trakcie";

      case Status.done:
        return "Zrobione";
    }
  }
}