import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class FriendServices extends ChangeNotifier {
  List<UserModel> _friends = [];
  List<UserModel> _requests = [];
  File? _file;
  File? _reqFile;

  List<UserModel> getFriends() => _friends;
  List<UserModel> getRequests() => _requests;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/friends.json');
    _reqFile = File('${directory.path}/friend_requests.json');

    if (_file!.existsSync()) {
      String content = await _file!.readAsString();
      if (content.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(content);
        _friends = jsonList.map((e) => UserModel.fromJson(e)).toList();
      }
    }

    if (_reqFile!.existsSync()) {
      String content = await _reqFile!.readAsString();
      if (content.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(content);
        _requests = jsonList.map((e) => UserModel.fromJson(e)).toList();
      }
    }
    notifyListeners();
  }

  Future<void> saveFriends() async {
    if (_file == null) return;
    String jsonList = jsonEncode(_friends.map((e) => e.toJson()).toList());
    await _file!.writeAsString(jsonList);
  }

  Future<void> saveRequests() async {
    if (_reqFile == null) return;
    String jsonList = jsonEncode(_requests.map((e) => e.toJson()).toList());
    await _reqFile!.writeAsString(jsonList);
  }

  void addFriend(UserModel friend) {
    if (!_friends.any((f) => f.uid == friend.uid)) {
      _friends = [..._friends, friend];
      saveFriends();
      notifyListeners();
    }
  }

  void receiveRequest(UserModel user) {
    if (!_requests.any((f) => f.uid == user.uid) && !_friends.any((f) => f.uid == user.uid)) {
      _requests = [..._requests, user];
      saveRequests();
      notifyListeners();
    }
  }

  void acceptRequest(UserModel user) {
    _requests = [..._requests..removeWhere((f) => f.uid == user.uid)];
    _friends = [..._friends, user];
    saveFriends();
    saveRequests();
    notifyListeners();
  }

  void declineRequest(String uid) {
    _requests = [..._requests..removeWhere((f) => f.uid == uid)];
    saveRequests();
    notifyListeners();
  }

  void removeFriend(String uid) {
    _friends = [..._friends..removeWhere((f) => f.uid == uid)];
    saveFriends();
    notifyListeners();
  }
}

final FriendServices friendServices = FriendServices();
