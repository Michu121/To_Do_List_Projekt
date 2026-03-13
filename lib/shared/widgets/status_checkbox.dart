import 'package:flutter/material.dart';
import 'package:todo_list/shared/models/status.dart';

class StatusCheckbox extends StatelessWidget {
  final Status status;
  final VoidCallback onTap;

  const StatusCheckbox({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == Status.done;
    final isInProgress = status == Status.inProgress;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Wypełnienie kolorem tylko gdy zadanie jest w toku lub zrobione
          color: isDone || isInProgress
              ? status.color
              : Colors.transparent,
          border: Border.all(
            color: status.color,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            status.icon,
            size: 25,
            color: isDone || isInProgress ? Colors.white : Colors.transparent,
          ),
        ),
      ),
    );
  }
}