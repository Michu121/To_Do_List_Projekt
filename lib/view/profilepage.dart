import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
                          'Completed Tasks (${completed.length})',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'incl. archived',
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
                      Text('No completed tasks yet',
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
            final friends = friendServices.getFriends();
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
                        _SectionHeader(
                            title: 'Friends',
                            trailing:
                            '${friends.length} friends'),
                        const SizedBox(height: 10),
                        _FriendsList(friends: friends),
                        const SizedBox(height: 20),
                        const _SectionHeader(title: 'Stats'),
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
                        const _SectionHeader(title: 'Groups'),
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
    // Ensure readable text colour on top of accent
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: onAccent.withValues(alpha: 0.4), width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
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
                  Text('Current League',
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
                  Text('Points',
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
          _Hint(Icons.add_task, 'Create task', '+5'),
          _Hint(Icons.check_circle, 'Complete', '+10~50'),
          _Hint(Icons.group_add, 'Join group', '+10'),
          _Hint(Icons.create_new_folder, 'New group', '+15'),
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

// ── Friends ───────────────────────────────────────────────────────────────────

class _FriendsList extends StatelessWidget {
  final List<UserModel> friends;
  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('No friends yet.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return Column(
        children: friends.map((f) => _FriendTile(friend: f)).toList());
  }
}

class _FriendTile extends StatelessWidget {
  final UserModel friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = friend.name.isNotEmpty
        ? friend.name
        .trim()
        .split(' ')
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase()
        : friend.email.isNotEmpty
        ? friend.email[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: friend.photo != null
              ? NetworkImage(friend.photo!)
              : null,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: friend.photo == null
              ? Text(initials,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer))
              : null,
        ),
        title: Text(
            friend.name.isNotEmpty ? friend.name : friend.email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: friend.name.isNotEmpty ? Text(friend.email) : null,
      ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '$tasksCompleted',
                label: 'Completed',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                onTap: onCompletedTap,
                tapHint: 'View all',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                value: '$tasksCreated',
                label: 'Created',
                icon: Icons.add_task,
                iconColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '$streakDays',
                label: 'Day streak',
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                value: '$groupsJoined',
                label: 'Groups joined',
                icon: Icons.groups_rounded,
                iconColor: Colors.purple,
              ),
            ),
          ],
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

// ── Groups Row ────────────────────────────────────────────────────────────────

class _GroupsRow extends StatelessWidget {
  final List<Group> groups;
  const _GroupsRow({required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('No groups yet.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: groups.map((g) => _GroupCircle(group: g)).toList(),
      ),
    );
  }
}

class _GroupCircle extends StatelessWidget {
  final Group group;
  const _GroupCircle({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: group.color,
            child: Text(
              group.name.isNotEmpty
                  ? group.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: group.color.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(
              group.name,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}