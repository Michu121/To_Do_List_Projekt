import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../shared/models/group.dart';
import '../shared/models/league.dart';
import '../shared/models/user_model.dart';
import '../shared/models/user_stats.dart';
import '../shared/services/friend_services.dart';
import '../shared/services/group_task_service.dart';
import '../shared/services/stats_service.dart';
import '../shared/services/task_services.dart';
import '../shared/services/user_stats_service.dart';
import '../shared/widgets/task_tiles/task_list_tile.dart';
import 'groupspage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    friendServices.init();
  }

  void _showCompletedTasks(BuildContext context) {
    final t = AppLocalizations.of(context);
    final completed = taskServices.getCompletedTasks()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '${t?.completedTasks ?? "Completed Tasks"} (${completed.length})',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          t?.incl_archived ?? 'incl. archived',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Divider(color: theme.dividerColor),
                  ],
                ),
              ),
              Expanded(
                child: completed.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt,
                          size: 60,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(t?.empty ?? 'No completed tasks yet',
                          style: TextStyle(
                              color: Colors.grey.shade500)),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: completed.length,
                  itemBuilder: (_, i) {
                    final task = completed[i];
                    return Stack(
                      children: [
                        TaskListTile(task: task),
                        if (task.isDeleted)
                          Positioned(
                            right: 22,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                'archived',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final currentUser = UserModel(
      uid: firebaseUser?.uid ?? '',
      email: firebaseUser?.email ?? '',
      name: firebaseUser?.displayName ?? 'User',
      photo: firebaseUser?.photoURL,
    );

    return StreamBuilder<UserStats?>(
      stream: statsService.watchMyStats(),
      builder: (context, statsSnap) {
        final fsStats = statsSnap.data;

        return ListenableBuilder(
          listenable: Listenable.merge(
              [userStatsService, groupTaskService, friendServices]),
          builder: (context, _) {
            final groups = groupTaskService.groups;
            final streak = userStatsService.streakDays;

            final points = fsStats?.points ?? userStatsService.totalPoints;
            final completed =
                fsStats?.tasksCompleted ?? userStatsService.doneCount;
            final created = fsStats?.tasksCreated ?? 0;
            final groupsJoined = fsStats?.groupsJoined ?? groups.length;
            final league = League.forPoints(points);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _ProfileHeader(user: currentUser),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LeagueCard(league: league, points: points),
                        const SizedBox(height: 20),
                        _SectionHeader(title: t?.stats ?? 'Stats'),
                        const SizedBox(height: 10),
                        _StatsGrid(
                          tasksCompleted: completed,
                          tasksCreated: created,
                          streakDays: streak,
                          groupsJoined: groupsJoined,
                          onCompletedTap: () =>
                              _showCompletedTasks(context),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(title: t?.group ?? 'Groups'),
                        const SizedBox(height: 10),
                        _GroupsRow(groups: groups),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent = accent.computeLuminance() > 0.4
        ? Colors.black87
        : Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.7)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      onAccent.withValues(alpha: 0.15),
                      onAccent.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onAccent.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: onAccent.withValues(alpha: 0.2),
                  backgroundImage: user.photo != null
                      ? NetworkImage(user.photo!)
                      : null,
                  child: user.photo == null
                      ? Icon(Icons.person, size: 52, color: onAccent)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name.isNotEmpty ? user.name : 'User',
            style: TextStyle(
                color: onAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
                color: onAccent.withValues(alpha: 0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── League Card ───────────────────────────────────────────────────────────────

class _LeagueCard extends StatelessWidget {
  final League league;
  final int points;
  const _LeagueCard({required this.league, required this.points});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = league.progressIn(points);
    final toNext = league.pointsToNext(points);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: league.badgeColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: league.badgeColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      league.badgeColor,
                      league.badgeColor.withValues(alpha: 0.6)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: league.badgeColor.withValues(alpha: 0.35),
                        blurRadius: 10)
                  ],
                ),
                child:
                Icon(league.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t?.currentLeague ?? 'Current League',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  Text(league.label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: league.badgeColor)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(t?.points ?? 'Points',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  Text('$points ✦',
                      style: TextStyle(
                          color: league.badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
              theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(league.badgeColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${league.minPoints} pts',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
              if (toNext > 0)
                Text('$toNext pts to next league',
                    style: TextStyle(
                        color:
                        league.badgeColor.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600))
              else
                Text('Max league! 🏆',
                    style: TextStyle(
                        color: league.badgeColor, fontSize: 11)),
              Text('${league.maxPoints} pts',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          _PointsLegend(),
        ],
      ),
    );
  }
}

class _PointsLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Hint(Icons.add_task, t?.addTask ?? 'Create task', '+5'),
          _Hint(Icons.check_circle, t?.complete ?? 'Complete', '+10~50'),
          _Hint(Icons.group_add, t?.joinGroup ?? 'Join group', '+10'),
          _Hint(Icons.create_new_folder, t?.createGroup ?? 'New group', '+15'),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.icon, this.label, this.pts);
  final IconData icon;
  final String label;
  final String pts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(pts,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (trailing != null)
          Text(trailing!,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
      ],
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int tasksCompleted;
  final int tasksCreated;
  final int streakDays;
  final int groupsJoined;
  final VoidCallback onCompletedTap;

  const _StatsGrid({
    required this.tasksCompleted,
    required this.tasksCreated,
    required this.streakDays,
    required this.groupsJoined,
    required this.onCompletedTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '$tasksCompleted',
                label: t?.tasksCompleted ?? 'Completed',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                onTap: onCompletedTap,
                tapHint: t?.viewAll ?? 'View all',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                value: '$tasksCreated',
                label: t?.tasksCreated ?? 'Created',
                icon: Icons.add_task,
                iconColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StatBox(
          value: '$streakDays',
          label: t?.dayStreak ?? 'Day streak',
          icon: Icons.local_fire_department,
          iconColor: Colors.deepOrange,
        ),
        const SizedBox(height: 6),
        Text(
          t?.pointsHistory ?? 'Points history',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tapHint;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.tapHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: onTap != null
              ? Border.all(
              color: iconColor.withValues(alpha: 0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22)),
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  if (tapHint != null)
                    Text(tapHint!,
                        style: TextStyle(
                            fontSize: 10,
                            color: iconColor,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: iconColor.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Groups Grid ───────────────────────────────────────────────────────────────

class _GroupsRow extends StatelessWidget {
  final List<Group> groups;
  const _GroupsRow({required this.groups});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.group_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(t?.noGroups ?? 'No groups yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...groups.map((g) => _GroupTile(group: g)),
            const _AddGroupButton(),
          ],
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Group group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(group: group),
          ),
        );
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: group.color.withValues(alpha: 0.1),
          border: Border.all(
            color: group.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: group.color,
              child: Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: group.color.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGroupButton extends StatelessWidget {
  const _AddGroupButton();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add group feature coming soon')),
        );
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.add,
                size: 24,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t?.addGroup ?? 'Add Group',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}