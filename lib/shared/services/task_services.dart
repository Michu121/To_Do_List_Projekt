import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/status.dart';
import '../models/task.dart';
import 'fire_store_service.dart';
import 'stats_service.dart';

class TaskServices extends ChangeNotifier {
  /// ALL tasks from Firestore including soft-deleted (for archive).
  List<Task> _allTasks = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  /// Active (non-deleted) tasks only.
  List<Task> getTasks() =>
      _allTasks.where((t) => !t.isDeleted).toList();

  /// All completed tasks including soft-deleted (for the profile archive).
  List<Task> getCompletedTasks() =>
      _allTasks.where((t) => t.status == Status.done).toList();

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.tasksStream(uid).listen((snapshot) {
      _allTasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _allTasks = [];
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    _allTasks = [..._allTasks, task];
    notifyListeners();

    unawaited(
      firestoreService
          .setTask(uid, task.id, task.toJson())
          .then((_) => statsService.onTaskCreated())
          .catchError((e) {
        _allTasks = _allTasks.where((t) => t.id != task.id).toList();
        notifyListeners();
        debugPrint('addTask error: $e');
      }),
    );
  }

  Future<void> updateTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    final oldIndex = _allTasks.indexWhere((t) => t.id == task.id);
    final oldTask = oldIndex >= 0 ? _allTasks[oldIndex] : null;

    final justCompleted = oldTask != null &&
        oldTask.status != Status.done &&
        task.status == Status.done;

    if (oldIndex >= 0) {
      _allTasks = [..._allTasks]..[oldIndex] = task;
      notifyListeners();
    }

    unawaited(
      firestoreService
          .updateTask(uid, task.id, task.toJson())
          .then((_) => justCompleted
          ? statsService.onTaskCompleted(task.difficulty.points)
          : Future.value())
          .catchError((e) {
        if (oldTask != null && oldIndex >= 0) {
          _allTasks = [..._allTasks]..[oldIndex] = oldTask;
          notifyListeners();
        }
        debugPrint('updateTask error: $e');
      }),
    );
  }

  Future<void> deleteTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;

    final idx = _allTasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _allTasks = [..._allTasks]..[idx] =
      _allTasks[idx].copyWith(isDeleted: true);
      notifyListeners();
    }

    unawaited(
      firestoreService.deleteTask(uid, task.id).catchError((e) {
        if (idx >= 0) {
          _allTasks = [..._allTasks]..[idx] = task;
          notifyListeners();
        }
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