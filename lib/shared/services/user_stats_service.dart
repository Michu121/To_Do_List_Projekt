import 'package:flutter/material.dart';
import '../models/status.dart';
import '../models/task.dart';
import '../models/league.dart';
import 'task_services.dart';

class UserStatsService extends ChangeNotifier {
  UserStatsService() {
    taskServices.addListener(_recompute);
    _recompute();
  }

  int _totalPoints = 0;
  int _doneCount = 0;
  int _inProgressCount = 0;
  int _streakDays = 0;

  int get totalPoints => _totalPoints;
  int get doneCount => _doneCount;
  int get inProgressCount => _inProgressCount;
  int get streakDays => _streakDays;
  League get league => League.forPoints(_totalPoints);

  void _recompute() {
    final tasks = taskServices.getTasks();

    final doneTasks = tasks.where((t) => t.status == Status.done).toList();

    _totalPoints = doneTasks.fold(0, (sum, t) => sum + t.difficulty.points);
    _doneCount = doneTasks.length;
    _inProgressCount = tasks.where((t) => t.status == Status.inProgress).length;
    _streakDays = _computeStreak(doneTasks);

    notifyListeners();
  }

  int _computeStreak(List<Task> doneTasks) {
    if (doneTasks.isEmpty) return 0;

    final completedDays = doneTasks
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    if (completedDays.first != todayNorm &&
        completedDays.first != todayNorm.subtract(const Duration(days: 1))) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < completedDays.length - 1; i++) {
      final diff = completedDays[i].difference(completedDays[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  void dispose() {
    taskServices.removeListener(_recompute);
    super.dispose();
  }
}

final userStatsService = UserStatsService();
