import 'package:flutter/material.dart';
void goToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600), // wolniejsza animacja
    ),
  );
}