import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'fire_store_service.dart';

class TaskServices extends ChangeNotifier {
  List<Task> _tasks = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  /// Returns only non-deleted tasks (filtered in Dart — no composite index needed).
  List<Task> getTasks() => _tasks.where((t) => !t.isDeleted).toList();

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.tasksStream(uid).listen((snapshot) {
      _tasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
          .where((t) => !t.isDeleted)
          .toList();
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _tasks = [];
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    // 1. Show immediately
    _tasks = [..._tasks, task];
    notifyListeners();

    // 2. Persist in background — roll back on failure
    unawaited(
      firestoreService.setTask(uid, task.id, task.toJson()).catchError((e) {
        _tasks = _tasks.where((t) => t.id != task.id).toList();
        notifyListeners();
        debugPrint('addTask error: $e');
      }),
    );
  }

  Future<void> updateTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    final oldIndex = _tasks.indexWhere((t) => t.id == task.id);
    final oldTask = oldIndex >= 0 ? _tasks[oldIndex] : null;

    // 1. Replace locally right away
    if (oldIndex >= 0) {
      _tasks = [..._tasks]..[oldIndex] = task;
      notifyListeners();
    }

    // 2. Persist in background — roll back on failure
    unawaited(
      firestoreService.updateTask(uid, task.id, task.toJson()).catchError((e) {
        if (oldTask != null && oldIndex >= 0) {
          _tasks = [..._tasks]..[oldIndex] = oldTask;
          notifyListeners();
        }
        debugPrint('updateTask error: $e');
      }),
    );
  }

  /// Soft-delete: marks isDeleted = true in Firestore.
  Future<void> deleteTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    // 1. Remove from local list immediately
    _tasks = _tasks.where((t) => t.id != task.id).toList();
    notifyListeners();

    // 2. Persist soft-delete in background — roll back on failure
    unawaited(
      firestoreService.deleteTask(uid, task.id).catchError((e) {
        _tasks = [..._tasks, task];
        notifyListeners();
        debugPrint('deleteTask error: $e');
      }),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final taskServices = TaskServices();