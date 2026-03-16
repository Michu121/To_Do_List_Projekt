import 'package:flutter/material.dart';

class League {
  final String name;
  final String label;
  final int minPoints;
  final int maxPoints;
  final Color color;
  final Color badgeColor;
  final IconData icon;

  const League({
    required this.name,
    required this.label,
    required this.minPoints,
    required this.maxPoints,
    required this.color,
    required this.badgeColor,
    required this.icon,
  });

  double progressIn(int points) {
    final range = maxPoints - minPoints;
    if (range <= 0) return 1.0;
    return ((points - minPoints) / range).clamp(0.0, 1.0);
  }

  int pointsToNext(int points) => (maxPoints - points).clamp(0, maxPoints);

  static const List<League> all = [
    League(
      name: 'bronze',
      label: 'Brązowa',
      minPoints: 0,
      maxPoints: 2000,
      color: Color(0xFFCD7F32),
      badgeColor: Color(0xFFCD7F32),
      icon: Icons.shield,
    ),
    League(
      name: 'silver',
      label: 'Srebrna',
      minPoints: 2000,
      maxPoints: 5000,
      color: Color(0xFF9E9E9E),
      badgeColor: Color(0xFFBDBDBD),
      icon: Icons.shield,
    ),
    League(
      name: 'gold',
      label: 'Złota',
      minPoints: 5000,
      maxPoints: 10000,
      color: Color(0xFFFFD700),
      badgeColor: Color(0xFFFFD700),
      icon: Icons.shield,
    ),
    League(
      name: 'platinum',
      label: 'Platynowa',
      minPoints: 10000,
      maxPoints: 20000,
      color: Color(0xFF00BCD4),
      badgeColor: Color(0xFF00BCD4),
      icon: Icons.shield,
    ),
    League(
      name: 'diamond',
      label: 'Diamentowa',
      minPoints: 20000,
      maxPoints: 999999,
      color: Color(0xFF7C4DFF),
      badgeColor: Color(0xFF7C4DFF),
      icon: Icons.diamond,
    ),
  ];

  static League forPoints(int points) {
    for (final league in all.reversed) {
      if (points >= league.minPoints) return league;
    }
    return all.first;
  }
}
