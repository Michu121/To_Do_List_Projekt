import 'package:flutter/material.dart';
import '../../screens/barrel.dart';
import 'package:todo_list/shared/modules/task_services.dart';
import 'package:todo_list/shared/modules/widgets.dart';
import 'package:todo_list/l10n/app_localizations.dart';
class MainPage extends StatefulWidget{
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage>{
  Page _activePage = Page.home;
  void setPage(Page page) {
    setState(() {
      _activePage = page;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const MyAppBar(),
      body: _activePage.pageWidget,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          var scale = Tween(begin: 0.0,end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack)
          );
          var offset = Tween<Offset>(begin: Offset(0,1),end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut)
          );
          return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scale,
                child: SlideTransition(position: offset, child: child),
              )
          );
        },
        child: _activePage.isFloating
            ?MyFloatingButton(onPressed: _activePage.onFloatClick)
            :null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomAppBar(isFloating: _activePage.isFloating,activePage: _activePage, onPageSelected: (page) => setPage(page)),
    );
  }
}
enum Page {
  home(isFloating: true, icon: Icons.home, value: "Home", pageWidget: HomePage(), onFloatClick: null),
  profile(isFloating: false, icon: Icons.account_circle, value: "Profile", pageWidget: ProfilePage()),
  groups(isFloating: true, icon: Icons.group, value: "Groups", pageWidget: GroupsPage(), onFloatClick: null),
  friends(isFloating: false, icon: Icons.person_add, value: "Friends", pageWidget: FriendsPage()),
  settings(isFloating: false, icon: Icons.settings, value: "Settings", pageWidget: SettingsPage()),
  calendar(isFloating: false, icon: Icons.calendar_month, value: "Calendar", pageWidget: CalendarPage());

  String getTransLabel(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (this) {
      case Page.home:
        return t.home;
      case Page.profile:
        return t.profile;
      case Page.groups:
        return t.group;
      case Page.friends:
        return t.friend;
      case Page.settings:
        return t.settings;
      case Page.calendar:
        return t.calendar;
    }
  }
  final bool isFloating;
  final IconData icon;
  final String value;
  final Widget pageWidget;
  final VoidCallback? onFloatClick;
  const Page({
    required this.isFloating,
    required this.icon,
    required this.value,
    required this.pageWidget,
    this.onFloatClick,
  });
}