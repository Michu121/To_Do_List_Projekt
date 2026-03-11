import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFF5C6BC0); // Indigo
  bool _menuButtonOnRight = true;
  String _language = 'English';

  bool _notificationsEnabled = false;
  bool _taskReminders = false;
  bool _friendInvitations = false;
  bool _groupInvitations = false;

  bool _privateProfile = false;
  bool _twoFactorAuth = false;
  bool _biometricLock = false;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get menuButtonOnRight => _menuButtonOnRight;
  String get language => _language;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskReminders => _taskReminders;
  bool get friendInvitations => _friendInvitations;
  bool get groupInvitations => _groupInvitations;

  bool get privateProfile => _privateProfile;
  bool get twoFactorAuth => _twoFactorAuth;
  bool get biometricLock => _biometricLock;

  void setThemeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  void setAccentColor(Color value) {
    _accentColor = value;
    notifyListeners();
  }

  void setMenuButtonPlacement(bool value) {
    _menuButtonOnRight = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    _language = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;

    if (!value) {
      _taskReminders = false;
      _friendInvitations = false;
      _groupInvitations = false;
    }

    notifyListeners();
  }

  void setTaskReminders(bool value) {
    if (!_notificationsEnabled) return;
    _taskReminders = value;
    notifyListeners();
  }

  void setFriendInvitations(bool value) {
    if (!_notificationsEnabled) return;
    _friendInvitations = value;
    notifyListeners();
  }

  void setGroupInvitations(bool value) {
    if (!_notificationsEnabled) return;
    _groupInvitations = value;
    notifyListeners();
  }

  void setPrivateProfile(bool value) {
    _privateProfile = value;
    notifyListeners();
  }

  void setTwoFactorAuth(bool value) {
    _twoFactorAuth = value;
    notifyListeners();
  }

  void setBiometricLock(bool value) {
    _biometricLock = value;
    notifyListeners();
  }
}