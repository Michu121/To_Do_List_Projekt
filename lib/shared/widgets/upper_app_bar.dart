import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key, required String title});
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