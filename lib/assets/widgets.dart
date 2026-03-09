import 'package:flutter/material.dart';
import 'package:todo_list/assets/functions.dart';
import 'package:todo_list/screens/homepage.dart';
import 'package:todo_list/screens/friendspage.dart';
import 'package:todo_list/screens/profilepage.dart';
import 'package:todo_list/screens/settingspage.dart';
import 'package:todo_list/screens/groupspage.dart';
//==================================================
//               Wyrwa w Bottom App Bar
//==================================================
class SmoothNotch extends NotchedShape {
  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null) return Path()..addRect(host);
    double top = host.top*0.6;
    final notchRadius = guest.width / 1.8;
    final notchCenter = guest.center.dx;

    const smooth = 0;

    final path = Path();
    path.moveTo(host.left, top);

    /// lewa strona przed wycięciem
    path.lineTo(notchCenter - notchRadius - smooth, top);

    /// lewa krzywa
    path.quadraticBezierTo(
      notchCenter - notchRadius,
      top,
      notchCenter - notchRadius,
      top + smooth,
    );

    /// półkole pod FAB
    path.arcToPoint(
      Offset(notchCenter + notchRadius, top + smooth),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    /// prawa krzywa
    path.quadraticBezierTo(
      notchCenter + notchRadius,
      top,
      notchCenter + notchRadius + smooth,
      top,
    );

    /// reszta paska
    path.lineTo(host.right, top);
    path.lineTo(host.right, host.bottom);
    path.lineTo(host.left, host.bottom);
    path.close();

    return path;
  }
}
class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 60, // promień koła
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(2),
        child: CircleAvatar(
          radius: 58, // promień koła
          backgroundImage: AssetImage("lib/assets/images/logo.png"),
        ),
      ),
    );
  }
}
//==================================================
//               Clasa AppBar
//==================================================
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // parametr tytułu

  const MyAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
          padding: EdgeInsets.only(left: 10), child: const LogoWidget()
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 35,
        ),
      ),
      backgroundColor: Colors.blueAccent,
      shadowColor: Colors.grey,
      elevation: 8,
    );
  }

  // PreferredSizeWidget wymaga implementacji preferredSize
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10); // wysokość AppBar
}
//==================================================
//               Clasa BottomAppBar
//==================================================
class MyBottomAppBar extends StatefulWidget {
  const MyBottomAppBar({super.key});

  @override
  State<MyBottomAppBar> createState() => _MyBottomAppBarState();
}

class _MyBottomAppBarState extends State<MyBottomAppBar> {
  final GlobalKey _moreKey = GlobalKey();
  bool _rotated = false; // kontrola obrotu ikony

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: BottomAppBar(
        color: Colors.blueAccent,
        shape: SmoothNotch(),
        notchMargin: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lewa część: Home + Profil
              Row(
                children: [
                  SizedBox(
                    width: 75,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: EdgeInsets.zero,
                        elevation: 4,
                      ),
                      onPressed: () => goToPage(context, const HomePage()),
                      child: const Icon(Icons.home, size: 35),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle, size: 35),
                    onPressed: () => goToPage(context, const ProfilePage()),
                  ),
                ],
              ),
              // Prawa część: Grupy + More
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.group, size: 35),
                    onPressed: () => goToPage(context, const GroupsPage()),
                  ),
                  GestureDetector(
                    key: _moreKey,
                    onTap: () async {
                      setState(() => _rotated = true); // obrót włączony

                      final RenderBox renderBox = _moreKey.currentContext!
                          .findRenderObject() as RenderBox;
                      final Offset offset = renderBox.localToGlobal(Offset.zero);

                      // Pokazanie menu rozwijanego w górę
                      final value = await showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          offset.dx,
                          offset.dy - 150, // menu lekko nad BottomAppBar
                          screenSize.width - offset.dx - renderBox.size.width,
                          0,
                        ),
                        color: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        items: [
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: const [
                                Icon(Icons.settings),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'friends',
                            child: Row(
                              children: const [
                                Icon(Icons.person_add),
                                SizedBox(width: 8),
                                Text('Friends'),
                              ],
                            ),
                          ),
                        ],
                      );

                      setState(() => _rotated = false); // obrót wraca

                      if (value == 'settings') goToPage(context, const SettingsPage());
                      if (value == 'friends') goToPage(context, const FriendsPage());
                    },
                    child: AnimatedRotation(
                      turns: _rotated ? -0.25 : 0, // 0.25 = 90 stopni
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.more_horiz, size: 35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}