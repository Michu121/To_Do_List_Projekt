import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';class League {
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

  // CHANGED: This is now a method, not a static list
  static List<League> all(BuildContext context) {
    final t = AppLocalizations.of(context);

    return [
      League(
        name: 'bronze',
        label: t?.bronze ?? 'Bronze',
        minPoints: 0,
        maxPoints: 2000,
        color: const Color(0xFFCD7F32),
        badgeColor: const Color(0xFFCD7F32),
        icon: Icons.shield,
      ),
      League(
        name: 'silver',
        label: t?.silver ?? 'Silver',
        minPoints: 2000,
        maxPoints: 5000,
        color: const Color(0xFF9E9E9E),
        badgeColor: const Color(0xFFBDBDBD),
        icon: Icons.shield,
      ),
      League(
        name: 'gold',
        label: t?.gold ?? 'Gold',
        minPoints: 5000,
        maxPoints: 10000,
        color: const Color(0xFFFFD700),
        badgeColor: const Color(0xFFFFD700),
        icon: Icons.shield,
      ),
      League(
        name: 'platinum',
        label: t?.platinum ?? 'Platinum',
        minPoints: 10000,
        maxPoints: 20000,
        color: const Color(0xFF00BCD4),
        badgeColor: const Color(0xFF00BCD4),
        icon: Icons.shield,
      ),
      League(
        name: 'diamond',
        label: t?.diamond ?? 'Diamond',
        minPoints: 20000,
        maxPoints: 999999,
        color: const Color(0xFF7C4DFF),
        badgeColor: const Color(0xFF7C4DFF),
        icon: Icons.diamond,
      ),
    ];
  }

  // CHANGED: Added context parameter here too
  static League forPoints(int points, BuildContext context) {
    final leagues = all(context);
    for (final league in leagues.reversed) {
      if (points >= league.minPoints) return league;
    }
    return leagues.first;
  }
}