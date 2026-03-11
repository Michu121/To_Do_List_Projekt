import 'package:flutter/material.dart' hide Page;
import 'package:todo_list/shared/screens/mainpage.dart';
import 'package:todo_list/shared/modules/task.dart';
import 'package:todo_list/shared/modules/task_services.dart';

//==================================================
//                    Logo
//==================================================
// class LogoWidget extends StatelessWidget {
//   const LogoWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const CircleAvatar(
//       radius: 26,
//       backgroundImage: AssetImage("lib/assets/images/logo.png"),
//     );
//   }
// }

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
// MyBottomAppBar
//==================================================
class MyBottomAppBar extends StatefulWidget {
  final bool isFloating;
  final Page activePage;
  // Dodajemy callback do komunikacji z rodzicem
  final Function(Page) onPageSelected;

  const MyBottomAppBar({
    super.key,
    this.isFloating = false,
    required this.activePage,
    required this.onPageSelected,
  });

  @override
  State<MyBottomAppBar> createState() => _MyBottomAppBarState();
}

class _MyBottomAppBarState extends State<MyBottomAppBar> {
  final GlobalKey _moreKey = GlobalKey();
  bool _rotated = false;

  // Lista stron używana w pasku
  final List<Page> _pages = [Page.home, Page.groups, Page.calendar, Page.profile, Page.friends, Page.settings];
  List<Page> get _morePages=> widget.isFloating ? _pages.sublist(3) : _pages.sublist(4);

  // Funkcja do zmiany aktywnej strony,

  Color _iconColor(Page page, BuildContext context, {Color? selectedColor, Color? unselectedColor}) {
    final theme = Theme.of(context);
    return widget.activePage == page
        ? (selectedColor ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.7))
        : (unselectedColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.3));
  }

  Color _moreColor(BuildContext context) {
    final theme = Theme.of(context);
    // Sprawdzamy, czy aktywna strona jest schowana w "More"
    bool inPopMenu = _morePages.contains(widget.activePage);

    return (inPopMenu || _rotated)
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.7);
  }

  Future<Page?> showMoreMenu(Offset offset) async {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return await showMenu<Page>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        screenSize.height - 200, // Dopasuj wysokość menu
        offset.dx,
        0,
      ),
      color: theme.bottomAppBarTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        for (var page in _morePages.reversed) _buildPopupMenuItem(page, context),
      ],
    );
  }

  PopupMenuItem<Page> _buildPopupMenuItem(Page page, BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuItem(
      value: page,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.activePage == page
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(page.icon, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(page.getTransLabel(context),
                style: TextStyle(color: theme.colorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(Page page, BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => widget.onPageSelected(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _iconColor(page, context),
          borderRadius: BorderRadius.circular(30),
        ),
        width: 55,
        height: 55,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Icon(page.icon, color: theme.colorScheme.onPrimary, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: BottomAppBar(
        shape: widget.isFloating ? SmoothNotch() : null,
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: widget.isFloating?MainAxisAlignment.spaceBetween:MainAxisAlignment.center,
          children: [
            // Lewa strona (Home, Groups)
            Row(children: [
              for (var page in _pages.sublist(0, 2)) _buildNavButton(page, context),
            ]),

            // Prawa strona (Calendar + More/Inne)
            Row(children: [
                ...(widget.isFloating ? [_buildNavButton(_pages[2], context)] : _pages.sublist(2, 4).map((page) => _buildNavButton(page, context)).toList()),
                GestureDetector(
                  key: _moreKey,
                  onTap: () async {
                    setState(() => _rotated = true);
                    final renderBox = _moreKey.currentContext!.findRenderObject() as RenderBox;
                    final offset = renderBox.localToGlobal(Offset.zero);

                    final selected = await showMoreMenu(offset);
                    setState(() => _rotated = false);

                    if (selected != null) widget.onPageSelected(selected);
                  },
                  child: AnimatedRotation(
                    turns: _rotated ? -0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.more_horiz, size: 35, color: _moreColor(context)),
                    ),
                  ),
                )
            ]),
          ],
        ),
      ),
    );
  }
}
//==========================================
//             Floatig Button
//==========================================
class MyFloatingButton extends StatefulWidget{
  final dynamic onPressed;
  const MyFloatingButton({super.key, required this.onPressed});
  @override
  State<MyFloatingButton> createState() => _MyFloatingButtonState();
}
class _MyFloatingButtonState extends State<MyFloatingButton>{
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(0,-2),
        child: SizedBox(
            height: 60,
            width: 60,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              child : Icon(Icons.add, size: 50,),
            )
        )
    );
  }
}
//==========================================
//             Task View
//==========================================
class TaskTile extends StatefulWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  @override
  Widget build(BuildContext context) {
    // Sprawdzamy stan na podstawie liczby
    bool isChecked = widget.task.status > 2;

    return ListTile(
      leading: Checkbox(
        value: isChecked,
        onChanged: (value) {
          setState(() {
            int newValue = isChecked ? widget.task.status - 1 : widget.task.status + 1;

            taskServices.updateTask(widget.task.copyWith(status: newValue));
          });
        },
      ),
      title: Text(
        widget.task.title,
        style: TextStyle(
          decoration: isChecked ? TextDecoration.lineThrough : null,
          color: isChecked ? Colors.grey : Colors.black,
        ),
      ),
      subtitle: Text(widget.task.description),
      trailing: Chip(label: Text(widget.task.category)),
    );
  }
}
