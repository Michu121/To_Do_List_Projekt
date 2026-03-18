import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<List<UserStats>> fetchMembersStats(List<String> uids) async {
    if (uids.isEmpty) return [];
    final futures = uids.map((uid) => _db.collection('users').doc(uid).get()).toList();
    final docs = await Future.wait(futures);
    final result = <UserStats>[];
    for (final doc in docs) {
      if (doc.exists && doc.data() != null) {
        result.add(UserStats.fromJson({...doc.data()!, 'uid': doc.id}));
      }
    }
    result.sort((a, b) => b.points.compareTo(a.points));
    return result;
  }
}

final statsService = StatsService();
