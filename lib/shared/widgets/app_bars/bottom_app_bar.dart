import 'dart:async';

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

class _MyBottomAppBarState extends State<MyBottomAppBar> with SingleTickerProviderStateMixin{
  final GlobalKey _moreKey = GlobalKey();
  bool _rotated = false;
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Animation<Offset>? _slideTransition;

  // Lista stron używana w pasku
  final List<Pages> _pages = [
    Pages.home,
    Pages.groups,
    Pages.calendar,
    Pages.profile,
    Pages.settings
  ];

  List<Pages> get _morePages =>
      widget.isFloating ? _pages.sublist(3) : _pages.sublist(4);

  // Funkcja do zmiany aktywnej strony,

  Color _iconColor(Pages page, BuildContext context,
      {Color? selectedColor, Color? unselectedColor}) {
    final theme = Theme.of(context);
    return widget.activePage == page
        ? (selectedColor ??
        theme.colorScheme.primaryContainer.withValues(alpha: 0.7))
        : (unselectedColor ??
        theme.colorScheme.onPrimary.withValues(alpha: 0.3));
  }

  Color _moreColor(BuildContext context) {
    final theme = Theme.of(context);
    // Sprawdzamy, czy aktywna strona jest schowana w "More"
    bool inPopMenu = _morePages.contains(widget.activePage);

    return (inPopMenu || _rotated)
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
        : theme.colorScheme.onPrimary.withValues(alpha: 0.3);
  }

  Future<Pages?> showMoreMenu() async {
    if (_overlayEntry != null) return null;
    int i = 0;
    final completer = Completer<Pages?>();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tło zamykające menu po kliknięciu poza nim
          GestureDetector(
            onTap: () {
              _hideMenu();
              if (!completer.isCompleted) completer.complete(null);
            },
            child: Container(color: Colors.transparent),
          ),

              Positioned(
                right: 0,
                bottom: 80, // Dopasuj do wysokości BottomAppBar
                child: SlideTransition(
                  position: _slideTransition!,
                  child: Material(
                    elevation: 10,
                    color: Theme.of(context).bottomAppBarTheme.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    child: IntrinsicWidth( // Dopasowuje szerokość do najdłuższego tekstu
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _morePages.reversed.map((page) {
                          bool end = i == _morePages.length-1;
                          bool start = i == 0;
                          ++i;
                          return _buildOverlayItem(
                              start ? BorderRadius.only(topLeft: Radius.circular(15)) : end ? BorderRadius.only(bottomLeft: Radius.circular(15)) : BorderRadius.zero,
                              page, (selectedPage) {
                            _hideMenu();
                            completer.complete(selectedPage);
                          });
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward();
    return completer.future;
  }

  Future<void> _hideMenu() async {
    if (_overlayEntry == null) return;
    await _animationController!.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayItem(BorderRadius radius,Pages page, Function(Pages) onSelect)  {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: radius,
      onTap: () => onSelect(page),
      child: Container(
        padding: EdgeInsetsGeometry.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: _iconColor(page, context,
              selectedColor: theme.colorScheme.primaryContainer),
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(page.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(page.getTransLabel(context),
              style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(width: 10),
          ],
        ),
      )
    );
  }

Widget _buildNavButton(Pages page, BuildContext context) {
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
      child: Icon(page.icon, color: Colors.white, size: 28),
    ),
  );
}
@override
void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), vsync: this,
    );
    _slideTransition = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,).animate(
          CurvedAnimation(parent: _animationController!,
              curve: Curves.easeInOut
          ),
    );
  }
@override
Widget build(BuildContext context) {
  return BottomAppBar(
    shape: widget.isFloating ? SmoothNotch() : null,
    notchMargin: 6,
    child: Row(
      mainAxisAlignment: widget.isFloating
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: [
        // Lewa strona (Home, Groups)
        Row(children: [
          for (var page in _pages.sublist(0, 2)) _buildNavButton(page, context),
        ]),

        // Prawa strona (Calendar + More/Inne)
        Row(children: [
          ...(widget.isFloating ? [_buildNavButton(_pages[2], context)] : _pages
              .sublist(2, 5)
              .map((page) => _buildNavButton(page, context))
              .toList()),
          if (widget.isFloating) ...[
          GestureDetector(
            key: _moreKey,
            onTap: () async {
              setState(() => _rotated = true);
              final selected = await showMoreMenu();
              setState(() => _rotated = false);

              if (selected != null) widget.onPageSelected(selected);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedRotation(
                turns: _rotated ? -0.25 : 0,
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: _moreColor(context),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  width: 55,
                  height: 55,
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_horiz, size: 35, color: Colors.white),
                ),
              ),
            ),
          )
        ]]),
      ],
    ),
  );
}
@override void dispose() {
    _hideMenu();
    _animationController!.dispose();
    super.dispose();
  }}