import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _tasksRef(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  CollectionReference _categoriesRef(String uid) =>
      _db.collection('users').doc(uid).collection('categories');

  CollectionReference _groupsRef(String uid) =>
      _db.collection('groups').doc(uid).collection('users');

  Future<void> afterLogin(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      final model = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photo: user.photoURL,
      );
      await ref.set(model.toJson());
    }
  }

  // ── User search ──────────────────────────────────────────────────────────────

  Future<UserModel?> findUserByEmail(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromJson(snapshot.docs.first.data());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  // ── Group members ────────────────────────────────────────────────────────────

  Future<void> addMemberToGroup(
      String ownerUid, String groupId, String memberUid) async {
    await _groupsRef(ownerUid).doc(groupId).update({
      'memberUids': FieldValue.arrayUnion([memberUid]),
    });
  }

  Future<void> removeMemberFromGroup(
      String ownerUid, String groupId, String memberUid) async {
    await _groupsRef(ownerUid).doc(groupId).update({
      'memberUids': FieldValue.arrayRemove([memberUid]),
    });
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  // FIX: removed `.where('isDeleted', isEqualTo: false)` — combining a where
  // filter with orderBy requires a composite Firestore index that may not exist,
  // causing the stream to fail silently. isDeleted is filtered in TaskServices
  // in Dart code instead, which requires no index.
  Stream<QuerySnapshot> tasksStream(String uid) =>
      _tasksRef(uid).orderBy('date').snapshots();

  Future<void> setTask(String uid, String id, Map<String, dynamic> data) =>
      _tasksRef(uid).doc(id).set(data);

  Future<void> updateTask(String uid, String id, Map<String, dynamic> data) =>
      _tasksRef(uid).doc(id).update(data);

  /// Soft-delete: marks the task as deleted instead of removing the document.
  Future<void> deleteTask(String uid, String id) =>
      _tasksRef(uid).doc(id).update({'isDeleted': true});

  // ── Categories ───────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> categoriesStream(String uid) =>
      _categoriesRef(uid).snapshots();

  Future<void> setCategory(String uid, String id, Map<String, dynamic> data) =>
      _categoriesRef(uid).doc(id).set(data);

  Future<void> deleteCategory(String uid, String id) =>
      _categoriesRef(uid).doc(id).delete();

  // ── Groups ───────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> groupsStream(String uid) =>
      _groupsRef(uid).snapshots();

  Future<void> setGroup(String uid, String id, Map<String, dynamic> data) =>
      _groupsRef(uid).doc(id).set(data);

  Future<void> deleteGroup(String uid, String id) =>
      _groupsRef(uid).doc(id).delete();
}

final firestoreService = FirestoreService();