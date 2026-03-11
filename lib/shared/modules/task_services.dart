import 'task.dart';
import 'dart:convert';
import 'dart:io';
class TaskServices {
  List<Task> _tasks = []; // Lista trzymająca stan w pamięci
  final String projectPath = Directory.current.path;
  late final File file = File('$projectPath/tasks.json');

  // Metoda do pobierania aktualnej listy
  List<Task> getTasks() => _tasks;

  void saveTasks() {
    String jsonList = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    // Upewnij się, że folder istnieje przed zapisem
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonList);
  }

  void init() {
    if (file.existsSync()) {
      String content = file.readAsStringSync();
      if (content.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(content);
        _tasks = jsonList.map((e) => Task.fromJson(e)).toList();
      }
    }
  }

  void addTask(Task task) {
    _tasks.add(task);
    saveTasks();
  }

  void updateTask(Task task) {
    int index = _tasks.indexWhere((element) => element.id == task.id);
    if (index != -1) {
      _tasks[index] = task; // Podmieniamy całe zadanie na nowe z copyWith
      saveTasks();
    }
  }
}
final taskServices = TaskServices();