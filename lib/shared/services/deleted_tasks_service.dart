import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/status.dart';
import '../models/task.dart';
import 'fire_store_service.dart';

class DeletedTasksService extends ChangeNotifier {
  /// All deleted tasks from Firestore
  List<Task> _deletedTasks = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  /// All deleted tasks that are marked as done
  List<Task> getCompletedDeletedTasks() =>
      _deletedTasks.where((t) => t.status == Status.done).toList();

  /// All deleted tasks
  List<Task> getDeletedTasks() => _deletedTasks;

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.tasksStream(uid).listen((snapshot) {
      // Filter only deleted tasks
      _deletedTasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
          .where((task) => task.isDeleted)
          .toList();
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _deletedTasks = [];
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Save a deleted completed task to Firebase
  Future<void> saveDeletedCompletedTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    // Ensure the task is marked as deleted and done
    final deletedTask = task.copyWith(isDeleted: true);

    if (!_deletedTasks.any((t) => t.id == deletedTask.id)) {
      _deletedTasks = [..._deletedTasks, deletedTask];
      notifyListeners();
    }

    await firestoreService.updateTask(uid, deletedTask.id, deletedTask.toJson());
  }
}

// Singleton instance
final deletedTasksService = DeletedTasksService();

