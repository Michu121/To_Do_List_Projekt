import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/shared/widgets/add_forms/add_group_form.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              '${t?.completedTasks ?? "Completed Tasks"} (${completed.length})',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t?.incl_archived ?? 'incl. archived',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: theme.colorScheme.outlineVariant),
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
                          size: 72,
                          color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 16),
                      Text(
                        t?.empty ?? 'No completed tasks yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: completed.length,
                  itemBuilder: (_, i) {
                    final task = completed[i];
                    return TaskListTile(task: task, disabled: true);
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LeagueCard(league: league, points: points),
                        const SizedBox(height: 32),
                        _SectionHeader(title: t?.stats ?? 'Stats'),
                        const SizedBox(height: 16),
                        _StatsGrid(
                          tasksCompleted: completed,
                          tasksCreated: created,
                          streakDays: streak,
                          groupsJoined: groupsJoined,
                          onCompletedTap: () => _showCompletedTasks(context),
                        ),
                        const SizedBox(height: 32),
                        _SectionHeader(title: t?.group ?? 'Groups'),
                        const SizedBox(height: 16),
                        _GroupsRow(groups: groups),
                        const SizedBox(height: 40),
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage:
                  user.photo != null ? NetworkImage(user.photo!) : null,
                  child: user.photo == null
                      ? Icon(Icons.person_rounded,
                      size: 56,
                      color: colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name.isNotEmpty ? user.name : 'User',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: league.badgeColor.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: league.badgeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      league.badgeColor,
                      league.badgeColor.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: league.badgeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(league.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t?.currentLeague ?? 'Current League',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      league.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: league.badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t?.points ?? 'Points',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$points ✦',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: league.badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(league.badgeColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${league.minPoints} ${t?.points ?? "pts"}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (toNext > 0)
                Text(
                  '$toNext ${t?.points ?? "pts"} to next league',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: league.badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  'Max league! 🏆',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: league.badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '${league.maxPoints} ${t?.points ?? "pts"}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Hint(Icons.add_task_rounded, t?.addTask ?? 'Create task', '+5'),
          _Hint(Icons.check_circle_rounded, t?.complete ?? 'Complete', '+10~50'),
          _Hint(Icons.group_add_rounded, t?.joinGroup ?? 'Join group', '+10'),
          _Hint(Icons.create_new_folder_rounded, t?.createGroup ?? 'New group', '+15'),
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
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          pts,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '$tasksCompleted',
                label: t?.tasksCompleted ?? 'Completed',
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
                onTap: onCompletedTap,
                tapHint: t?.viewAll ?? 'View all',
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _StatBox(
                value: '$tasksCreated',
                label: t?.tasksCreated ?? 'Created',
                icon: Icons.add_task_rounded,
                iconColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatBox(
          value: '$streakDays',
          label: t?.dayStreak ?? 'Day streak',
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.deepOrange,
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (tapHint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tapHint!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Groups row ────────────────────────────────────────────────────────────────

class _GroupsRow extends StatelessWidget {
  final List<Group> groups;
  const _GroupsRow({required this.groups});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.group_off_rounded,
                size: 48, color: theme.colorScheme.surfaceContainerHighest),
            const SizedBox(height: 12),
            Text(
              t?.noGroups ?? 'No groups yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => GroupActionsOverlay.show(context),
              icon: const Icon(Icons.add),
              label: Text(t?.addGroup ?? 'Add Group'),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...groups.map((g) => _GroupTile(group: g)),
        const _AddGroupButton(),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Group group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: group.color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: group.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupDetailPage(group: group),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: group.color,
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: group.color.computeLuminance() > 0.4
                        ? Colors.black87
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                group.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => GroupActionsOverlay.show(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                child: Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t?.addGroup ?? 'Add Group',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}