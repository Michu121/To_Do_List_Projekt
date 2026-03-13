import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // DODAJ TO
import 'dart:convert';
import 'dart:io';
import '../models/group.dart';

class GroupServices extends ChangeNotifier {
  List<Group> _groups = [];
  File? _file; // Plik będzie dostępny dopiero po inicjalizacji

  List<Group> getGroups() => _groups;

  // 1. Zmieniamy inicjalizację na asynchroniczną
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/groups.json');

    if (_file!.existsSync()) {
      String content = await _file!.readAsString();
      if (content.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(content);
        _groups = jsonList.map((e) => Group.fromJson(e)).toList();
        notifyListeners(); // Ważne: powiadom o wczytanych danych!
      }
    }
  }

  Future<void> saveGroups() async {
    if (_file == null) return;

    String jsonList = jsonEncode(_groups.map((e) => e.toJson()).toList());
    await _file!.writeAsString(jsonList);
  }

  void addGroup(Group group) {
    _groups = [..._groups, group];
    saveGroups();
    notifyListeners();
  }

  void updateGroup(Group group) {
    int index = _groups.indexWhere((element) => element.id == group.id);
    _groups = [..._groups..removeAt(index)..insert(index, group)];
    saveGroups();
    notifyListeners();
  }
  void deleteGroup(Group group) {
    _groups = [..._groups..removeWhere((element) => element.id == group.id)];
    saveGroups();
    notifyListeners();
  }
}
final GroupServices groupServices = GroupServices();