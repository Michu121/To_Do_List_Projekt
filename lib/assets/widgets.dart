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
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      foregroundColor: theme.appBarTheme.foregroundColor,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(10); // Standardowa wysokość AppBar
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
  bool _rotated = false, _inPopMenu = false;
  final List<AppPage> _pages = [AppPage.home, AppPage.groups, AppPage.calendar, AppPage.profile, AppPage.friends, AppPage.settings];
  late final List<AppPage> _morePages = _pages.sublist(_pages.length - 3);

  Color _iconColor(AppPage page, BuildContext context, {Color? selectedColor, Color? unselectedColor}) {
    final theme = Theme.of(context);
    return widget.activePage == page 
        ? (selectedColor ?? theme.colorScheme.primaryContainer.withOpacity(0.7)) 
        : (unselectedColor ?? theme.colorScheme.onPrimary.withOpacity(0.3));
  }

  Color _moreColor(BuildContext context) {
    final theme = Theme.of(context);
    for (var page in _morePages){
        if (widget.activePage == page)
        {
          _inPopMenu = true;
        }
    }
    return _inPopMenu ? theme.colorScheme.onPrimary : _rotated ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimary.withOpacity(0.7);
  }

  Future<AppPage?> showMoreMenu(Offset offset) async {
    final RenderBox renderBox = _moreKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return await showMenu<AppPage>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        screenSize.height - screenSize.height*0.28,
        screenSize.width - offset.dx - size.width- 20,
        0,
      ),
      menuPadding: EdgeInsets.zero,
      color: theme.bottomAppBarTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        for (var page in _morePages.reversed) _buildPopupMenuItem(page, context),
      ],
    );
  }

  PopupMenuItem<AppPage> _buildPopupMenuItem(AppPage page, BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuItem(
      value: page,
      child: Container(
        padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _iconColor(page, context, selectedColor: theme.colorScheme.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
          children: [
            Icon(page.icon, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(page.label, style: TextStyle(color: theme.colorScheme.onPrimary)),
          ],
        ),
      )
    );
  }

  Widget _buildNavButton(AppPage page, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _iconColor(page, context),
          borderRadius: BorderRadius.circular(30),
        ),
        width: widget.isFloating? 55 : 49.8,
        height: 50,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => goToPage(context, page.pageWidget),
          child: Icon(page.icon, color: theme.colorScheme.onPrimary, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: BottomAppBar(
        color: theme.bottomAppBarTheme.color,
        elevation: theme.bottomAppBarTheme.elevation,
        shape: widget.isFloating ? (theme.bottomAppBarTheme.shape ?? SmoothNotch()) : null,
        notchMargin: widget.isFloating ? 6 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  for (var page in _pages.sublist(0, 2))
                    _buildNavButton(page, context),
                ],
              ),
              Row(
                children: [
                  _buildNavButton(_pages[2], context),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.more_horiz, size: 35, color: _moreColor(context)),
                        )
                      ),
                    )
                  else
                    for (var page in _morePages)
                      _buildNavButton(page, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
