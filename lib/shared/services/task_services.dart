import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'fire_store_service.dart';

class TaskServices extends ChangeNotifier {
  List<Task> _tasks = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Task> getTasks() => _tasks;

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.tasksStream(uid).listen((snapshot) {
      _tasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
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
    await firestoreService.setTask(uid, task.id, task.toJson());
  }

  Future<void> updateTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.updateTask(uid, task.id, task.toJson());
  }

  Future<void> deleteTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.deleteTask(uid, task.id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final taskServices = TaskServices();