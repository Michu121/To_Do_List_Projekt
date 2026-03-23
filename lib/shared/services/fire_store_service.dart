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
      _db.collection('users').doc(uid).collection('groups');

  CollectionReference _friendsRef(String uid) =>
      _db.collection('users').doc(uid).collection('friends');

  CollectionReference _requestsRef(String uid) =>
      _db.collection('users').doc(uid).collection('friendRequests');

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

  // ── Friends & Requests ───────────────────────────────────────────────────────

  Stream<QuerySnapshot> friendsStream(String uid) => _friendsRef(uid).snapshots();

  Stream<QuerySnapshot> requestsStream(String uid) => _requestsRef(uid).snapshots();

  Future<void> sendFriendRequest(UserModel fromUser, String toUid) async {
    await _requestsRef(toUid).doc(fromUser.uid).set(fromUser.toJson());
  }

  Future<void> acceptFriendRequest(UserModel currentUser, UserModel friendUser) async {
    final batch = _db.batch();

    // Add to my friends
    batch.set(_friendsRef(currentUser.uid).doc(friendUser.uid), friendUser.toJson());
    // Add to their friends
    batch.set(_friendsRef(friendUser.uid).doc(currentUser.uid), currentUser.toJson());
    // Remove request
    batch.delete(_requestsRef(currentUser.uid).doc(friendUser.uid));

    await batch.commit();
  }

  Future<void> declineFriendRequest(String myUid, String friendUid) async {
    await _requestsRef(myUid).doc(friendUid).delete();
  }

  Future<void> removeFriend(String myUid, String friendUid) async {
    final batch = _db.batch();
    batch.delete(_friendsRef(myUid).doc(friendUid));
    batch.delete(_friendsRef(friendUid).doc(myUid));
    await batch.commit();
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

  Stream<QuerySnapshot> tasksStream(String uid) =>
      _tasksRef(uid).orderBy('date').snapshots();

  Future<void> setTask(String uid, String id, Map<String, dynamic> data) =>
      _tasksRef(uid).doc(id).set(data);

  Future<void> updateTask(String uid, String id, Map<String, dynamic> data) =>
      _tasksRef(uid).doc(id).update(data);

  Future<void> deleteTask(String uid, String id) =>
      _tasksRef(uid).doc(id).delete();

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