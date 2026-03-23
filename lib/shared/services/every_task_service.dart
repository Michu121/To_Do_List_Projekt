import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_services.dart';
import 'group_task_service.dart';

/// Aggregates personal tasks (taskServices) and group tasks (groupTaskService)
/// into a single stream. Consumers only need to listen to this one service.
class EveryTaskService extends ChangeNotifier {
  EveryTaskService() {
    taskServices.addListener(notifyListeners);
    groupTaskService.addListener(notifyListeners);
  }

  bool get loading => groupTaskService.loading;

  /// Returns all non-deleted personal + group tasks.
  /// uid is checked dynamically so this works correctly after login.
  List<Task> getTasks() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return [...taskServices.getTasks(), ...groupTaskService.tasks];
  }

  /// Soft-deletes a task from the correct service.
  /// [gid] is task.group?.id — may be null for personal tasks.
  void removeTask(String? gid, Task task) {
    final resolvedGid = gid ?? groupTaskService.groupIdOf(task.id);
    if (resolvedGid != null) {
      groupTaskService.deleteTask(resolvedGid, task.id);
    } else {
      taskServices.deleteTask(task);
    }
  }

  @override
  void dispose() {
    taskServices.removeListener(notifyListeners);
    groupTaskService.removeListener(notifyListeners);
    super.dispose();
  }
}

final everyTaskService = EveryTaskService();