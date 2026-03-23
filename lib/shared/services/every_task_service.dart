import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_services.dart';
import 'group_task_service.dart';

class EveryTaskService extends ChangeNotifier {
  // FIX: nullable — never force-unwrap; the service is safe to create even
  // before the user is confirmed logged in.
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  bool get loading => groupTaskService.loading;

  EveryTaskService() {
    final u = uid;
    if (u != null) {
      taskServices.init(u);
    }
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

  /// Returns all non-deleted personal + group tasks, or an empty list when
  /// the user is not logged in.
  List<Task> getTasks() {
    if (uid == null) return [];
    return [...taskServices.getTasks(), ...groupTaskService.tasks];
  }

  /// Soft-deletes a task from the correct service.
  ///
  /// [gid] is task.group?.id — may be null for tasks created before the group
  /// field was persisted. Falls back to [groupTaskService.groupIdOf] which
  /// scans the in-memory map so deletion always hits the right collection.
  void removeTask(String? gid, Task task) {
    final resolvedGid = gid ?? groupTaskService.groupIdOf(task.id);
    if (resolvedGid != null) {
      groupTaskService.deleteTask(resolvedGid, task.id);
    } else {
      taskServices.deleteTask(task);
    }
  }
}

final everyTaskService = EveryTaskService();