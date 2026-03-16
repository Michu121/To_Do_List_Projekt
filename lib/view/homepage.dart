import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import '../shared/services/task_services.dart';
import '../shared/widgets/task_list_tile.dart';
class HomePage extends StatefulWidget{
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListenableBuilder(
        listenable: taskServices,
        builder: (context,child) {
          final tasks = taskServices.getTasks();
          if (tasks.isEmpty) {
            return Center(
              child: Text(t.notask, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20)),
            );
          }
          return ListView.builder(
            itemCount: tasks.length+1,
            itemBuilder: (context, index) {
              if (index == tasks.length){
                return SizedBox(height: 30);
              }
              final task = tasks[index];
              return TaskTile(task: task);
              },
            physics: const BouncingScrollPhysics(),
          );
        }
      );
  }
}
