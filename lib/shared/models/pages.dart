import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../view/barrel.dart';

enum Pages{
  home(isFloating: true, icon: Icons.home, value: "Home", pageWidget: HomePage()),
  profile(isFloating: false, icon: Icons.account_circle, value: "Profile", pageWidget: ProfilePage()),
  groups(isFloating: true, icon: Icons.group, value: "Groups", pageWidget: GroupsPage()),
  friends(isFloating: false, icon: Icons.person_add, value: "Friends", pageWidget: FriendsPage()),
  settings(isFloating: false, icon: Icons.settings, value: "Settings", pageWidget: SettingsPage()),
  calendar(isFloating: false, icon: Icons.calendar_month, value: "Calendar", pageWidget: CalendarPage());

  String getTransLabel(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (this) {
      case Pages.home:
        return t!.home;
      case Pages.profile:
        return t!.profile;
      case Pages.groups:
        return t!.group;
      case Pages.friends:
        return t!.friend;
      case Pages.settings:
        return t!.settings;
      case Pages.calendar:
        return t!.calendar;
    }
  }
  final bool isFloating;
  final IconData icon;
  final String value;
  final Widget pageWidget;
  const Pages({
    required this.isFloating,
    required this.icon,
    required this.value,
    required this.pageWidget,
  });
}