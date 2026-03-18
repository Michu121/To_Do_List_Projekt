import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_services.dart';
import 'group_task_service.dart';

class EveryTaskService extends ChangeNotifier {
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
    return [...taskServices.getTasks(), ...groupTaskService.tasks];
  }

  /// Soft-deletes the task. The Firestore stream will push the update back,
  /// removing it from the UI automatically — no local mutation needed.
  void removeTask(String? gid, Task task) {
    if (gid == null) {
      taskServices.deleteTask(task);
    } else {
      groupTaskService.deleteTask(gid, task.id);
    }
  }
}

final everyTaskService = EveryTaskService();