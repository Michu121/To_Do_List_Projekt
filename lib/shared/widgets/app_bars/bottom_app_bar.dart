import 'package:flutter/material.dart';
import '../../models/pages.dart';
import '../../notches/smoth_notch.dart';

class MyBottomAppBar extends StatefulWidget {
  final bool isFloating;
  final Pages activePage;
  // Dodajemy callback do komunikacji z rodzicem
  final Function(Pages) onPageSelected;

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
  final List<Pages> _pages = [Pages.home, Pages.groups, Pages.calendar, Pages.profile, Pages.friends, Pages.settings];
  List<Pages> get _morePages=> widget.isFloating ? _pages.sublist(3) : _pages.sublist(4);

  // Funkcja do zmiany aktywnej strony,

  Color _iconColor(Pages page, BuildContext context, {Color? selectedColor, Color? unselectedColor}) {
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

  Future<Pages?> showMoreMenu(Offset offset) async {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return await showMenu<Pages>(
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

  PopupMenuItem<Pages> _buildPopupMenuItem(Pages page, BuildContext context) {
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

  Widget _buildNavButton(Pages page, BuildContext context) {
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