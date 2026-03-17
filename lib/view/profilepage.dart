import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../shared/models/user_stats.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/group_task_service.dart';
import '../shared/services/stats_service.dart';
import 'loginpage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data;
        if (user == null) return const LoginPage();
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});
  final User user;

  String _initials() {
    final name = user.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return user.email?[0].toUpperCase() ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<UserStats?>(
      stream: statsService.watchMyStats(),
      builder: (context, statsSnap) {
        final stats = statsSnap.data;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _AvatarSection(user: user, initials: _initials(), theme: theme),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : 'User',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user.email ?? '',
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 16),
            if (stats != null) _RankBadge(stats: stats),
            const SizedBox(height: 20),
            _StatsGrid(stats: stats),
            const SizedBox(height: 28),
            _SectionTitle('Points breakdown'),
            const SizedBox(height: 10),
            _PointsBreakdown(),
            const SizedBox(height: 28),
            _SectionTitle('Account'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: user.email ?? '',
            ),
            _SettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Email verified',
              subtitle:
              user.emailVerified ? 'Verified' : 'Not verified',
              trailing: user.emailVerified
                  ? const Icon(Icons.check_circle,
                  color: Colors.green, size: 18)
                  : TextButton(
                onPressed: () => user.sendEmailVerification(),
                child: const Text('Verify',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Actions'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign out',
              iconColor: Colors.red.shade400,
              titleColor: Colors.red.shade400,
              onTap: () async {
                await AuthService().logout();
                groupTaskService.reset();
              },
            ),
          ],
        );
      },
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.user,
    required this.initials,
    required this.theme,
  });
  final User user;
  final String initials;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            backgroundColor:
            theme.colorScheme.primary.withValues(alpha: 0.15),
            child: user.photoURL == null
                ? Text(
              initials,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
                : null,
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.scaffoldBackgroundColor, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child:
            const Icon(Icons.person, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final rank = UserStats.rankTitle(stats.points);
    final progress = _progressToNext(stats.points);
    final nextThreshold = _nextThreshold(stats.points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withValues(alpha: 0.15),
            Colors.blueAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.blueAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rank,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stats.points} pts',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (nextThreshold != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                Colors.blueAccent.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(
                    Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.points} / $nextThreshold pts to next rank',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  static const _thresholds = [20, 50, 100, 200, 500];

  double _progressToNext(int pts) {
    for (int i = 0; i < _thresholds.length; i++) {
      if (pts < _thresholds[i]) {
        final prev = i == 0 ? 0 : _thresholds[i - 1];
        final range = _thresholds[i] - prev;
        return (pts - prev) / range;
      }
    }
    return 1.0;
  }

  int? _nextThreshold(int pts) {
    for (final t in _thresholds) {
      if (pts < t) return t;
    }
    return null;
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final UserStats? stats;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (context, _) {
        final groupCount = groupTaskService.groups.length;
        final taskCount = groupTaskService.tasks.length;
        final doneCount = groupTaskService.tasks
            .where((t) => t.status.status == 2)
            .length;
        final points = stats?.points ?? 0;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              value: '$points',
              label: 'Total Points',
              icon: Icons.star_rounded,
              color: Colors.amber.shade600,
            ),
            _StatCard(
              value: '$groupCount',
              label: 'Groups',
              icon: Icons.group_rounded,
              color: Colors.blueAccent,
            ),
            _StatCard(
              value: '$taskCount',
              label: 'Tasks',
              icon: Icons.task_alt,
              color: Colors.teal,
            ),
            _StatCard(
              value: '$doneCount',
              label: 'Completed',
              icon: Icons.check_circle_rounded,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsBreakdown extends StatelessWidget {
  const _PointsBreakdown();

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
      Icons.add_task,
      'Create a task',
      '+${StatsService.pointsCreateTask} pts',
      Colors.teal
      ),
      (
      Icons.check_circle_outline,
      'Complete a task',
      '+${StatsService.pointsCompleteTask} pts',
      Colors.green
      ),
      (
      Icons.group_add,
      'Create a group',
      '+${StatsService.pointsCreateGroup} pts',
      Colors.blueAccent
      ),
      (
      Icons.login,
      'Join a group',
      '+${StatsService.pointsJoinGroup} pts',
      Colors.purple
      ),
    ];

    return Column(
      children: rows.map((r) {
        final (icon, label, pts, color) = r;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border:
            Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pts,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, size: 18)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}