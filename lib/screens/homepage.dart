import 'package:flutter/material.dart';
import 'package:todo_list/shared/modules/task_services.dart';
import 'package:todo_list/shared/modules/task.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/modules/widgets.dart';
class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  @override
  void initState() {
    super.initState();
    taskServices.init();
  }


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tasks = taskServices.getTasks();

    if (tasks.isEmpty) {
      return Center(
        child: TextButton(
          child: const Text("Add First Task"),
          onPressed: () {
            setState(() {
              taskServices.addTask(Task(
                id: DateTime.now().millisecondsSinceEpoch,
                title: "New Task",
                status: 0,
                category: "Category",
                group: "Group",
                description: "Description",
                date: DateTime.now(),
                timeStart: TimeOfDay.now(),
                timeEnd: TimeOfDay.now(),
              ));
            });
          },
        ),
      );
    } else {
      return Column(
        children: [
          // Przycisk na górze
          TextButton(
            child: const Text("Add Another Task"),
            onPressed: () {
              setState(() {
                taskServices.addTask(Task(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: "New Task",
                  status: 0,
                  category: "Category",
                  group: "Group",
                  description: "Description",
                  date: DateTime.now(),
                  timeStart: TimeOfDay.now(),
                  timeEnd: TimeOfDay.now(),
                ));
              });
            },
          ),
          // Expanded naprawia błąd wysokości
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskTile(task: task);
              },
            ),
          ),
        ],
      );
    }
  }
}
