import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_services.dart';
import 'group_task_service.dart';

class EveryTaskService extends ChangeNotifier{
  final uid = FirebaseAuth.instance.currentUser?.uid;

  bool get loading => groupTaskService.loading;

  EveryTaskService() {
    taskServices.init(uid!);
    groupTaskService.init();
    taskServices.addListener(notifyListeners);
    groupTaskService.addListener(notifyListeners);
  }
  @override
  void dispose() {
    taskServices.removeListener(notifyListeners);
    groupTaskService.removeListener(notifyListeners);
    super.dispose();
  }
  List<Task>? getTasks() {
    if (uid == null) return null;
    return [...taskServices.getTasks(),...groupTaskService.tasks];
  }
  void removeTask(String? gid,Task task) {
    if (uid == null) return;
    if (task.group == null && gid == null) {
       taskServices.deleteTask(task);
    }else{
      groupTaskService.deleteTask(task.group!.id, task.id);
    }
  }
}

final everyTaskService = EveryTaskService();