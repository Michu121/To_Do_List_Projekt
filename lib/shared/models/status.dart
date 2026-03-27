import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';

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

  static Status fromInt(int value) {
    return Status.values.firstWhere(
          (e) => e.status == value,
      orElse: () => Status.todo,
    );
  }

  int toInt() {
    return status;
  }
}

extension StatusName on Status {
  // CHANGE: Pass context into the method instead of trying to get it from nowhere
  String label(BuildContext context) {
    final t = AppLocalizations.of(context);

    switch (this) {
      case Status.todo:
        return t?.todo ?? 'To do';

      case Status.inProgress:
        return t?.inProgress ?? 'In progress';

      case Status.done:
        return t?.done ?? 'Done';
    }
  }
}