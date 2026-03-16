import 'package:flutter/material.dart';

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