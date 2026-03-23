import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'fire_store_service.dart';

class FriendServices extends ChangeNotifier {
  List<UserModel> _friends = [];
  List<UserModel> _requests = [];
  
  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;

  List<UserModel> getFriends() => _friends;
  List<UserModel> getRequests() => _requests;

  void init() {
    final user = authService.currentUser;
    if (user == null) return;

    _friendsSub?.cancel();
    _requestsSub?.cancel();

    _friendsSub = firestoreService.friendsStream(user.uid).listen((snapshot) {
      _friends = snapshot.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });

    _requestsSub = firestoreService.requestsStream(user.uid).listen((snapshot) {
      _requests = snapshot.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }

  Future<String?> sendRequestByEmail(String email) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return "Nie jesteś zalogowany";

    final targetUser = await firestoreService.findUserByEmail(email);
    if (targetUser == null) return "Użytkownik nie znaleziony";
    if (targetUser.uid == currentUser.uid) return "Nie możesz dodać siebie";

    final myModel = UserModel(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      name: currentUser.displayName ?? 'Użytkownik',
      photo: currentUser.photoURL,
    );

    await firestoreService.sendFriendRequest(myModel, targetUser.uid);
    return null; // Sukces
  }

  Future<void> acceptRequest(UserModel user) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final myModel = UserModel(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      name: currentUser.displayName ?? 'Użytkownik',
      photo: currentUser.photoURL,
    );

    await firestoreService.acceptFriendRequest(myModel, user);
  }

  Future<void> declineRequest(String uid) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;
    await firestoreService.declineFriendRequest(currentUser.uid, uid);
  }

  Future<void> removeFriend(String uid) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;
    await firestoreService.removeFriend(currentUser.uid, uid);
  }
}

final FriendServices friendServices = FriendServices();
