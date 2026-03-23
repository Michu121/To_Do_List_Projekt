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

  // ── Init ──────────────────────────────────────────────────────────────────

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
        .listen(_onGroupsSnapshot, onError: (e) {
      debugPrint('GroupTaskService groups stream error: $e');
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

  // ── Snapshot handlers ─────────────────────────────────────────────────────

  void _onGroupsSnapshot(QuerySnapshot snapshot) {
    _groups = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Group.fromJson({...data, 'id': doc.id});
    }).toList();

    final activeIds = _groups.map((g) => g.id).toSet();

    for (final id in _taskSubs.keys
        .where((id) => !activeIds.contains(id))
        .toList()) {
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
          onError: (e) =>
              debugPrint('tasks stream error (${group.id}): $e'),
        );
      }
    }

    if (_groups.isEmpty) {
      _tasks = [];
      _loading = false;
    } else if (_taskSubs.isEmpty) {
      _loading = false;
    }

    notifyListeners();
  }

  void _onTasksSnapshot(String groupId, QuerySnapshot snapshot) {
    _tasksByGroup[groupId] = snapshot.docs
        .map((doc) => Task.fromJson(
        {...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
        .where((t) => !t.isDeleted)
        .toList();

    _rebuildTaskList();
    _loading = false;
    notifyListeners();
  }

  void _rebuildTaskList() {
    _tasks = _tasksByGroup.values
        .expand((list) => list)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Public helpers ────────────────────────────────────────────────────────

  String? groupIdOf(String taskId) {
    for (final entry in _tasksByGroup.entries) {
      if (entry.value.any((t) => t.id == taskId)) return entry.key;
    }
    return null;
  }

  List<Task> tasksForGroup(String groupId) => List.unmodifiable(
      (_tasksByGroup[groupId] ?? []).where((t) => !t.isDeleted));

  // ── Group CRUD ────────────────────────────────────────────────────────────

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
    final group = Group.fromJson(data);

    _groups = [..._groups, group];
    _tasksByGroup[group.id] = [];
    notifyListeners();

    unawaited(
      ref.set(data).then((_) => statsService.onGroupCreated()).catchError((e) {
        _groups = _groups.where((g) => g.id != group.id).toList();
        _tasksByGroup.remove(group.id);
        _rebuildTaskList();
        notifyListeners();
        debugPrint('createGroup error: $e');
      }),
    );

    return group;
  }

  Future<bool> joinGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([uid]),
      });
    } on FirebaseException catch (e) {
      debugPrint('joinGroup FirebaseException: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('joinGroup unexpected: $e');
      return false;
    }

    unawaited(statsService.onGroupJoined().catchError(
            (e) => debugPrint('onGroupJoined stats error: $e')));
    return true;
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    unawaited(
      _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([uid]),
      }),
    );
  }

  void removeMember(String groupId, String memberUid) {
    unawaited(
      _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberUid]),
      }).catchError((e) => debugPrint('removeMember error: $e')),
    );
  }

  void deleteGroup(String groupId) {
    _groups = _groups.where((g) => g.id != groupId).toList();
    _tasksByGroup.remove(groupId);
    _taskSubs[groupId]?.cancel();
    _taskSubs.remove(groupId);
    _rebuildTaskList();
    notifyListeners();

    unawaited(
      _db
          .collection('groups')
          .doc(groupId)
          .delete()
          .catchError((e) => debugPrint('deleteGroup error: $e')),
    );
  }

  // ── Task CRUD — fully optimistic ─────────────────────────────────────────

  void addTask(String groupId, Task task) {
    _tasksByGroup.putIfAbsent(groupId, () => []).add(task);
    _rebuildTaskList();
    notifyListeners();

    unawaited(
      _db
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson())
          .then((_) => statsService.onTaskCreated())
          .catchError((e) {
        _tasksByGroup[groupId]?.removeWhere((t) => t.id == task.id);
        _rebuildTaskList();
        notifyListeners();
        debugPrint('addTask error: $e');
      }),
    );
  }

  void updateTask(String groupId, Task newTask) {
    final bucket = _tasksByGroup[groupId];
    final oldIndex = bucket?.indexWhere((t) => t.id == newTask.id) ?? -1;
    final oldTask = oldIndex >= 0 ? bucket![oldIndex] : null;

    final justCompleted = oldTask != null &&
        oldTask.status != Status.done &&
        newTask.status == Status.done;

    if (oldIndex >= 0) {
      bucket![oldIndex] = newTask;
      _rebuildTaskList();
      notifyListeners();
    }

    unawaited(
      _db
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(newTask.id)
          .set(newTask.toJson())
          .then((_) => justCompleted
          ? statsService.onTaskCompleted(newTask.difficulty.points)
          : Future.value())
          .catchError((e) {
        if (oldTask != null && oldIndex >= 0) {
          _tasksByGroup[groupId]?[oldIndex] = oldTask;
          _rebuildTaskList();
          notifyListeners();
        }
        debugPrint('updateTask error: $e');
      }),
    );
  }

  void deleteTask(String groupId, String taskId) {
    _tasksByGroup[groupId]?.removeWhere((t) => t.id == taskId);
    _rebuildTaskList();
    notifyListeners();

    unawaited(
      _db
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .update({'isDeleted': true})
          .catchError(
              (e) => debugPrint('deleteTask error: $e')),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

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