import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_stats.dart';

class StatsService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const int pointsCreateTask = 5;
  static const int pointsCreateGroup = 15;
  static const int pointsJoinGroup = 10;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  Future<void> _increment(Map<String, dynamic> fields) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.set(fields, SetOptions(merge: true));
  }

  /// Called when a task is created. Awards [pointsCreateTask] points.
  Future<void> onTaskCreated() async {
    await _increment({
      'points': FieldValue.increment(pointsCreateTask),
      'tasksCreated': FieldValue.increment(1),
    });
  }

  /// Called when a task is marked as done.
  /// Awards the task's difficulty points (10 / 25 / 50).
  Future<void> onTaskCompleted(int difficultyPoints) async {
    await _increment({
      'points': FieldValue.increment(difficultyPoints),
      'tasksCompleted': FieldValue.increment(1),
    });
  }

  Future<void> onGroupCreated() async {
    await _increment({
      'points': FieldValue.increment(pointsCreateGroup),
      'groupsJoined': FieldValue.increment(1),
    });
  }

  Future<void> onGroupJoined() async {
    await _increment({
      'points': FieldValue.increment(pointsJoinGroup),
      'groupsJoined': FieldValue.increment(1),
    });
  }

  Stream<UserStats?> watchMyStats() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserStats.fromJson({...doc.data()!, 'uid': uid});
    });
  }

  /// Fetches stats for each member individually.
  Future<List<UserStats>> fetchMembersStats(List<String> uids) async {
    if (uids.isEmpty) return [];

    final results = await Future.wait(
      uids.map((uid) async {
        try {
          final doc = await _db.collection('users').doc(uid).get();
          if (!doc.exists || doc.data() == null) return null;
          return UserStats.fromJson({...doc.data()!, 'uid': doc.id});
        } catch (e) {
          debugPrint('fetchMembersStats: could not load uid=$uid — $e');
          return null;
        }
      }),
    );

    final stats = results.whereType<UserStats>().toList();
    stats.sort((a, b) => b.points.compareTo(a.points));
    return stats;
  }
}

final statsService = StatsService();