import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_stats.dart';

class StatsService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const int pointsCreateTask = 2;
  static const int pointsCompleteTask = 10;
  static const int pointsCreateGroup = 5;
  static const int pointsJoinGroup = 3;

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

  Future<void> onTaskCreated() async {
    await _increment({
      'points': FieldValue.increment(pointsCreateTask),
      'tasksCreated': FieldValue.increment(1),
    });
  }

  Future<void> onTaskCompleted() async {
    await _increment({
      'points': FieldValue.increment(pointsCompleteTask),
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
  /// If a document can't be read (e.g. permission-denied for another user's
  /// doc under strict Firestore rules), that member is silently skipped
  /// instead of crashing the whole leaderboard.
  Future<List<UserStats>> fetchMembersStats(List<String> uids) async {
    if (uids.isEmpty) return [];

    final results = await Future.wait(
      uids.map((uid) async {
        try {
          final doc = await _db.collection('users').doc(uid).get();
          if (!doc.exists || doc.data() == null) return null;
          return UserStats.fromJson({...doc.data()!, 'uid': doc.id});
        } catch (e) {
          // Permission-denied or network error for this specific user —
          // skip them rather than failing the whole leaderboard.
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