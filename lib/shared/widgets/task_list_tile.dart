import 'package:flutter/material.dart';
import 'package:todo_list/shared/models/status.dart';
import 'package:todo_list/shared/widgets/dismissible_remove_background.dart';
import 'package:todo_list/shared/widgets/status_checkbox.dart';
import '../models/task.dart';
import '../services/task_services.dart';
import 'delete_confirmation_dialog.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.task.status;
    final isDone = currentStatus == Status.done;

    // Przenosimy margines tutaj jako Padding
    return Container(
        clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          boxShadow:
          [
            BoxShadow(
              color: widget.task.color,
              blurRadius: 3,
              spreadRadius: 2,
            )
          ]
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: Dismissible(
          key: Key(widget.task.id),
          resizeDuration: const Duration(milliseconds: 150),
          movementDuration: const Duration(milliseconds: 200),
          onDismissed: (direction) {
            taskServices.deleteTask(widget.task);
          },
          confirmDismiss: (direction) async {
            if (widget.task.status == Status.done) return true;
            return await DeleteConfirmationDialog().show(context) ?? false;
          },
          onUpdate: (details) {

          },
          background: const DismissibleRemoveBackground(mainAxisAlignment: MainAxisAlignment.start),
          secondaryBackground: const DismissibleRemoveBackground(mainAxisAlignment: MainAxisAlignment.end),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: StatusCheckbox(
                status: currentStatus,
                onTap: () {
                  Status nextStatus;
                  if (currentStatus == Status.todo) {
                    nextStatus = Status.inProgress;
                  } else if (currentStatus == Status.inProgress) {
                    nextStatus = Status.done;
                  } else {
                    nextStatus = Status.todo;
                  }
                  final updatedTask = widget.task.copyWith(status: nextStatus);
                  taskServices.updateTask(updatedTask);
                  setState(() {});
                }),
                title: Text(
                  widget.task.title,
                  style: TextStyle(
                    fontSize: 30,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.task.formatDate(widget.task.date)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(label: Text(widget.task.category.name), backgroundColor: widget.task.category.color, padding: EdgeInsets.zero),
                                widget.task.group == null ? Container() : Chip(label: Text(widget.task.group!.name), backgroundColor: widget.task.group!.color, padding: EdgeInsets.zero)
                              ],
                            ),
                          ]
                      )
                    ]
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}