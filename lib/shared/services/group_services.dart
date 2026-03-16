import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/user_model.dart';
import 'fire_store_service.dart';

class GroupServices extends ChangeNotifier {
  List<Group> _groups = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Group> getGroups() => _groups;

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.groupsStream(uid).listen((snapshot) {
      _groups = snapshot.docs
          .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _groups = [];
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addGroup(Group group) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.setGroup(uid, group.id, group.toJson());
  }

  Future<void> updateGroup(Group group) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.setGroup(uid, group.id, group.toJson());
  }

  Future<void> deleteGroup(Group group) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.deleteGroup(uid, group.id);
  }

  // ── Members ──────────────────────────────────────────────────────────────────

  Future<UserModel?> findUserByEmail(String email) =>
      firestoreService.findUserByEmail(email);

  Future<void> addMember(String groupId, String memberUid) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.addMemberToGroup(uid, groupId, memberUid);
  }

  Future<void> removeMember(String groupId, String memberUid) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.removeMemberFromGroup(uid, groupId, memberUid);
  }

  Future<List<UserModel>> getMembers(Group group) async {
    final results = await Future.wait(
      group.memberUids.map((uid) => firestoreService.getUserById(uid)),
    );
    return results.whereType<UserModel>().toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final groupServices = GroupServices();