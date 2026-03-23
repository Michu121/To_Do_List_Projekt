import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    bool granted = false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(
          alert: true, badge: true, sound: true);
      granted = result ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;
    }
    return granted;
  }

  Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required DateTime taskDateTime,
    required int minutesBefore,
  }) async {
    if (!_initialized) await init();
    final notifyAt =
    taskDateTime.subtract(Duration(minutes: minutesBefore));
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = taskId.hashCode.abs() % 2147483647;
    final body = minutesBefore == 0
        ? 'Your task is due now!'
        : 'Due in $minutesBefore min';

    await _plugin.zonedSchedule(
      id,
      '📋 $title',
      body,
      tz.TZDateTime.from(notifyAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for upcoming tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('Notification scheduled for $notifyAt: $title');
  }

  Future<void> cancelNotification(String taskId) async {
    final id = taskId.hashCode.abs() % 2147483647;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}

final notificationService = NotificationService.instance;