import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark }

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const List<Color> availableAccentColors = [
    Color(0xFF5C6BC0), // blue
    Color(0xFF4CAF50), // green
    Color(0xFFEC407A), // pink
    Color(0xFFFFA726), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF26C6DA), // cyan
    Color(0xFFEF5350), // red
  ];

  late SharedPreferences _prefs;

  AppThemeMode _themeMode = AppThemeMode.light;
  Color _accentColor = availableAccentColors.first;
  String _language = 'English';

  bool _notificationsEnabled = false;
  bool _taskReminders = false;
  bool _invitations = false;
  bool _groupInvitations = false;

  bool _biometricLock = false;
  bool _lockWhenBackgrounded = false;
  bool _hideNotificationContent = false;

  AppThemeMode get themeMode => _themeMode;

  ThemeMode get materialThemeMode =>
      _themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

  String get themeLabel => _themeMode == AppThemeMode.dark ? 'Dark' : 'Light';
  Color get accentColor => _accentColor;
  String get language => _language;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskReminders => _taskReminders;
  bool get invitations => _invitations;
  bool get groupInvitations => _groupInvitations;

  bool get biometricLock => _biometricLock;
  bool get lockWhenBackgrounded => _lockWhenBackgrounded;
  bool get hideNotificationContent => _hideNotificationContent;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final savedTheme = _prefs.getString('theme_mode');
    _themeMode = savedTheme == 'dark' ? AppThemeMode.dark : AppThemeMode.light;

    _accentColor = Color(
      _prefs.getInt('accent_color') ??
          availableAccentColors.first.toARGB32(),
    );

    _language = 'English';

    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? false;
    _taskReminders = _prefs.getBool('task_reminders') ?? false;
    _invitations = _prefs.getBool('invitations') ?? false;
    _groupInvitations = _prefs.getBool('group_invitations') ?? false;

    _biometricLock = _prefs.getBool('biometric_lock') ?? false;
    _lockWhenBackgrounded =
        _prefs.getBool('lock_when_backgrounded') ?? false;
    _hideNotificationContent =
        _prefs.getBool('hide_notification_content') ?? false;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt('accent_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = 'English';
    await _prefs.setString('language', 'English');
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications_enabled', value);

    if (!value) {
      _taskReminders = false;
      _invitations = false;
      _groupInvitations = false;

      await _prefs.setBool('task_reminders', false);
      await _prefs.setBool('invitations', false);
      await _prefs.setBool('group_invitations', false);
    }

    notifyListeners();
  }

  Future<void> setTaskReminders(bool value) async {
    _taskReminders = value;
    await _prefs.setBool('task_reminders', value);
    notifyListeners();
  }

  Future<void> setInvitations(bool value) async {
    _invitations = value;
    await _prefs.setBool('invitations', value);
    notifyListeners();
  }

  Future<void> setGroupInvitations(bool value) async {
    _groupInvitations = value;
    await _prefs.setBool('group_invitations', value);
    notifyListeners();
  }

  Future<void> setBiometricLock(bool value) async {
    _biometricLock = value;
    await _prefs.setBool('biometric_lock', value);
    notifyListeners();
  }

  Future<void> setLockWhenBackgrounded(bool value) async {
    _lockWhenBackgrounded = value;
    await _prefs.setBool('lock_when_backgrounded', value);
    notifyListeners();
  }

  Future<void> setHideNotificationContent(bool value) async {
    _hideNotificationContent = value;
    await _prefs.setBool('hide_notification_content', value);
    notifyListeners();
  }
}