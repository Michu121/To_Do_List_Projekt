import 'package:flutter/material.dart';
import 'package:todo_list/assets/functions.dart';
import 'package:todo_list/screens/barrel.dart';

//==================================================
//                    Logo
//==================================================
class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 26,
      backgroundImage: AssetImage("lib/assets/images/logo.png"),
    );
  }
}

//==================================================
//                    AppBar
//==================================================
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      elevation: 8,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(10);
}

//==================================================
//                   Wyrwa pod FAB
//==================================================

class SmoothNotch extends NotchedShape {
  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null) return Path()..addRect(host);
    double top = host.top * 0.6;
    final notchRadius = guest.width / 1.8;
    final notchCenter = guest.center.dx;

    final path = Path();
    path.moveTo(host.left, top);
    path.lineTo(notchCenter - notchRadius, top);
    path.arcToPoint(
      Offset(notchCenter + notchRadius, top),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(host.right, top);
    path.lineTo(host.right, host.bottom);
    path.lineTo(host.left, host.bottom);
    path.close();
    return path;
  }
}


//==================================================
// Enum AppPage z ikonami i labelami
//==================================================
enum AppPage {
  home(icon: Icons.home, label: "Home", pageWidget: HomePage()),
  profile(icon: Icons.account_circle, label: "Profile", pageWidget: ProfilePage()),
  groups(icon: Icons.group, label: "Groups", pageWidget: GroupsPage()),
  friends(icon: Icons.person_add, label: "Friends", pageWidget: FriendsPage()),
  settings(icon: Icons.settings, label: "Settings", pageWidget: SettingsPage()),
  calendar(icon: Icons.calendar_month, label: "Calendar", pageWidget: CalendarPage());

  final IconData icon;
  final String label;
  final Widget pageWidget;

  const AppPage({
    required this.icon,
    required this.label,
    required this.pageWidget,
  });
}

//==================================================
// MyBottomAppBar
//==================================================
class MyBottomAppBar extends StatefulWidget {
  final bool isFloating;
  final AppPage activePage;

  const MyBottomAppBar({
    super.key,
    this.isFloating = false,
    this.activePage = AppPage.home,
  });

  @override
  State<MyBottomAppBar> createState() => _MyBottomAppBarState();
}

class _MyBottomAppBarState extends State<MyBottomAppBar> {
  final GlobalKey _moreKey = GlobalKey();
  final bool inPopMenu = false;
  bool _rotated = false;

  Color _iconColor(AppPage page, {Color? selectedColor, Color? unselectedColor}) {
    return widget.activePage == page ? selectedColor??Colors.blue.shade600 : unselectedColor??Colors.white24;
  }
  Color _moreColor() {
    for (var page in [AppPage.settings,AppPage.friends, AppPage.groups]){
        if (widget.activePage == page)
        {
          return Colors.white;
        }
    }
    return _rotated ? Colors.white : Colors.white70;
  }
  Future<AppPage?> showMoreMenu(Offset offset) async {
    final RenderBox renderBox = _moreKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    return await showMenu<AppPage>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        screenSize.height - screenSize.height*0.28,
        screenSize.width - offset.dx - size.width,
        0,
      ),
      menuPadding: EdgeInsets.zero,
      color: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        for (var page in [AppPage.settings,AppPage.friends, AppPage.groups]) _buildPopupMenuItem(page),
      ],
    );
  }
  PopupMenuItem<AppPage> _buildPopupMenuItem(AppPage page) {
    return PopupMenuItem(
      value: page,
      child: Container(
        padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _iconColor(page,selectedColor: Colors.blue.shade800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
          children: [
            Icon(page.icon, color: Colors.white),
            Text(page.label, style: TextStyle(color: Colors.white)),
          ],
        ),
      )
    );
  }
  Widget _buildNavButton(AppPage page) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _iconColor(page),
          borderRadius: BorderRadius.circular(30),
        ),
        width: widget.isFloating? 55 : 49.8,
        height: 50,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => goToPage(context, page.pageWidget),
          child: Icon(page.icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BottomAppBar(
        color: Colors.blueAccent,
        shape: widget.isFloating ? SmoothNotch() : null,
        notchMargin: widget.isFloating ? 6 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lewa część: home + profile
              Row(
                children: [
                  for (var page in [AppPage.home, AppPage.profile])
                    _buildNavButton(page),
                ],
              ),
              // Prawa część: groups + more/friends+settings
              Row(
                children: [
                  _buildNavButton(AppPage.calendar),
                  if (widget.isFloating)
                    GestureDetector(
                      key: _moreKey,
                      onTap: () async {
                        setState(() => _rotated = true);

                        final renderBox = _moreKey.currentContext!
                            .findRenderObject() as RenderBox;
                        final offset = renderBox.localToGlobal(Offset.zero);

                        final value = await showMoreMenu(offset);

                        setState(() => _rotated = false);
                        for (var page in AppPage.values){
                          if (value == page)
                          {
                            goToPage(context, page.pageWidget);
                          }
                        }
                      },
                      child: AnimatedRotation(
                        turns: _rotated ? -0.25 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.more_horiz, size: 35, color: _moreColor()),
                        )
                      ),
                    )
                  else
                    for (var page in [AppPage.groups,AppPage.friends, AppPage.settings])
                      _buildNavButton(page),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}