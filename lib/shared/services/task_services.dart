import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // DODAJ TO
import 'dart:convert';
import 'dart:io';
import '../models/task.dart';

class TaskServices extends ChangeNotifier {
  List<Task> _tasks = [];
  File? _file; // Plik będzie dostępny dopiero po inicjalizacji

  List<Task> getTasks() => _tasks;

  // 1. Zmieniamy inicjalizację na asynchroniczną
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/tasks.json');

    if (_file!.existsSync()) {
      String content = await _file!.readAsString();
      if (content.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(content);
        _tasks = jsonList.map((e) => Task.fromJson(e)).toList();
        notifyListeners(); // Ważne: powiadom o wczytanych danych!
      }
    }
  }

  Future<void> saveTasks() async {
    if (_file == null) return;

    String jsonList = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await _file!.writeAsString(jsonList);
  }

  void addTask(Task task) {
  _tasks = [..._tasks, task];
  saveTasks();
  notifyListeners();
  }

  void updateTask(Task task) {
    int index = _tasks.indexWhere((element) => element.id == task.id);
    _tasks = [..._tasks..removeAt(index)..insert(index, task)];
    saveTasks();
    notifyListeners();
  }
  void deleteTask(Task task) {
    _tasks = [..._tasks..removeWhere((element) => element.id == task.id)];
    saveTasks();
    notifyListeners();
  }
}
final TaskServices taskServices = TaskServices();