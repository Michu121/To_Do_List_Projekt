import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/status.dart';
import '../models/task.dart';
import 'stats_service.dart';

class GroupTaskService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Group> _groups = [];
  List<Task> _tasks = [];
  bool _loading = false;

  List<Group> get groups => List.unmodifiable(_groups);
  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get loading => _loading;

  StreamSubscription<QuerySnapshot>? _groupsSub;
  final Map<String, StreamSubscription<QuerySnapshot>> _taskSubs = {};
  final Map<String, List<Task>> _tasksByGroup = {};

  void init() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _cancelTaskSubs();
    _groupsSub?.cancel();

    _loading = true;
    notifyListeners();

    _groupsSub = _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .listen(_onGroupsSnapshot, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  void _cancelTaskSubs() {
    for (final sub in _taskSubs.values) {
      sub.cancel();
    }
    _taskSubs.clear();
    _tasksByGroup.clear();
  }

  void _onGroupsSnapshot(QuerySnapshot snapshot) {
    _groups = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Group.fromJson({...data, 'id': doc.id});
    }).toList();

    final activeIds = _groups.map((g) => g.id).toSet();

    final staleIds = _taskSubs.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in staleIds) {
      _taskSubs[id]?.cancel();
      _taskSubs.remove(id);
      _tasksByGroup.remove(id);
    }

    for (final group in _groups) {
      if (!_taskSubs.containsKey(group.id)) {
        _taskSubs[group.id] = _db
            .collection('groups')
            .doc(group.id)
            .collection('tasks')
            .orderBy('date')
            .snapshots()
            .listen(
              (snap) => _onTasksSnapshot(group.id, snap),
          onError: (_) {},
        );
      }
    }

    if (_groups.isEmpty) {
      _tasks = [];
      _loading = false;
    }

    notifyListeners();
  }

  void _onTasksSnapshot(String groupId, QuerySnapshot snapshot) {
    _tasksByGroup[groupId] = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Task.fromJson({...data, 'id': doc.id});
    }).toList();

    _tasks = _tasksByGroup.values
        .expand((list) => list)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    _loading = false;
    notifyListeners();
  }

  Future<Group?> createGroup(String name, int colorValue) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final ref = _db.collection('groups').doc();
    final data = {
      'id': ref.id,
      'name': name,
      'color': colorValue,
      'members': [uid],
      'createdBy': uid,
    };
    await ref.set(data);
    await statsService.onGroupCreated();
    return Group.fromJson(data);
  }

  Future<bool> joinGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) return false;

    final members = List<String>.from(
      (doc.data() as Map<String, dynamic>)['members'] as List? ?? [],
    );
    if (members.contains(uid)) return true;

    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
    await statsService.onGroupJoined();
    return true;
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> addTask(String groupId, Task task) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
    await statsService.onTaskCreated();
  }

  Future<void> updateTask(String groupId, Task newTask) async {
    final existing = _tasksByGroup[groupId]
        ?.where((t) => t.id == newTask.id)
        .firstOrNull;

    final justCompleted = existing != null &&
        existing.status != Status.done &&
        newTask.status == Status.done;

    await _db
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .doc(newTask.id)
        .set(newTask.toJson());

    if (justCompleted) {
      await statsService.onTaskCompleted();
    }
  }

  Future<void> deleteTask(String groupId, String taskId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  List<Task> tasksForGroup(String groupId) {
    return List.unmodifiable(_tasksByGroup[groupId] ?? []);
  }

  void reset() {
    _groupsSub?.cancel();
    _groupsSub = null;
    _cancelTaskSubs();
    _groups = [];
    _tasks = [];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

final groupTaskService = GroupTaskService();