import 'package:flutter/material.dart';
import 'package:todo_list/shared/models/status.dart';
import '../models/task.dart';
import '../services/task_services.dart';

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
    // Sprawdzamy stan na podstawie liczby
    return
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                color: Colors.white,
                border: Border(left: BorderSide(
                  color: widget.task.color,
                  width: 20,
                )
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          child: ListTile(
          leading: IconButton(
            onPressed: () {
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

              setState(() {
              });
            },
            icon: Icon(currentStatus.icon, color: currentStatus.color),
          ),
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
              Text(widget.task.description),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.task.formatDate(widget.task.date)),
                  Chip(label: Text(widget.task.category.name), backgroundColor: widget.task.category.color,padding: EdgeInsets.zero,),
                  Chip(label: Text(widget.task.group.name), backgroundColor: widget.task.group.color,padding: EdgeInsets.zero)
                ]
                
              )
            ]
          ),
        )
            ),
      );
  }
}