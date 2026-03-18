import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../shared/models/group.dart';
import '../shared/models/league.dart';
import '../shared/models/user_model.dart';
import '../shared/services/group_services.dart';
import '../shared/services/user_stats_service.dart';
import 'friendspage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserModel _mockUser = UserModel(
    uid: '${FirebaseAuth.instance.currentUser!.uid}',
    email: '${FirebaseAuth.instance.currentUser!.email}',
    name: '${FirebaseAuth.instance.currentUser!.displayName}',
    photo: '${FirebaseAuth.instance.currentUser!.photoURL}',
  );

  // Mock friends – replace with real friends service data
  final List<_FriendStats> _friends = [
    _FriendStats(name: 'NickName', points: 1500, leagueName: 'bronze', photo: null),
    _FriendStats(name: 'Alex', points: 3200, leagueName: 'silver', photo: 'shared/images/logo.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([userStatsService, groupServices]),
      builder: (context, _) {
        final stats = userStatsService;
        final league = stats.league;
        final groups = groupServices.getGroups();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(user: _mockUser),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LeagueCard(
                      league: league,
                      points: stats.totalPoints,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Znajomi', trailing: '${_friends.length} znajomych'),
                    const SizedBox(height: 10),
                    _FriendsList(friends: _friends),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Statystyki'),
                    const SizedBox(height: 10),
                    _StatsRow(
                      doneCount: stats.doneCount,
                      inProgressCount: stats.inProgressCount,
                      streakDays: stats.streakDays,
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Grupy'),
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
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A7BD5), Color(0xFF6A3DE8)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha:0.6), width: 3),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withValues(alpha:0.2),
              backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
              child: user.photo == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name.isNotEmpty ? user.name : 'NickName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── League Card ─────────────────────────────────────────────────────────────

class _LeagueCard extends StatelessWidget {
  final League league;
  final int points;
  const _LeagueCard({required this.league, required this.points});

  @override
  Widget build(BuildContext context) {
    final progress = league.progressIn(points);
    final toNext = league.pointsToNext(points);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: league.badgeColor.withValues(alpha:0.15),
                child: Text(
                  league.label[0],
                  style: TextStyle(color: league.badgeColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Liga', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    league.label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: league.badgeColor),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Punkty', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    '$points',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(league.color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Punkty', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text(
                '$points/${league.maxPoints}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          if (toNext > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$toNext Punkty(-ów) do następnej ligi',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

// ── Friends ──────────────────────────────────────────────────────────────────

class _FriendStats {
  final String name;
  final int points;
  final String leagueName;
  final String? photo;
  _FriendStats({required this.name, required this.points, required this.leagueName, this.photo});
}

class _FriendsList extends StatelessWidget {
  final List<_FriendStats> friends;
  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...friends.map((f) => _FriendTile(friend: f)),
        _AddFriendTile(),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final _FriendStats friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    final league = League.all.firstWhere(
          (l) => l.name == friend.leagueName,
      orElse: () => League.all.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: friend.photo != null ? NetworkImage(friend.photo!) : null,
          backgroundColor: Colors.grey.shade300,
          child: friend.photo == null
              ? Text(friend.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: league.badgeColor.withValues(alpha:0.15),
              child: Text(
                league.label[0],
                style: TextStyle(color: league.badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Text(league.label, style: TextStyle(color: league.badgeColor, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '${friend.points}',
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFriendTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: () {
          // TODO: open add friend sheet
        },
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          child: Icon(Icons.add, color: Colors.grey.shade500),
        ),
        title: Text('Dodaj znajomego', style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int doneCount;
  final int inProgressCount;
  final int streakDays;
  const _StatsRow({required this.doneCount, required this.inProgressCount, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            value: '$doneCount',
            label: 'Wykonane',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '$inProgressCount',
            label: 'W trakcie',
            icon: Icons.access_time_filled,
            iconColor: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '$streakDays',
            label: 'Dni z rzędu',
            icon: Icons.local_fire_department,
            iconColor: Colors.deepOrange,
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
  const _StatBox({required this.value, required this.label, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Groups Row ───────────────────────────────────────────────────────────────

class _GroupsRow extends StatelessWidget {
  final List<Group> groups;
  const _GroupsRow({required this.groups});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ...groups.map((g) => _GroupCircle(group: g)),
          _AddGroupCircle(),
        ],
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
      child: CircleAvatar(
        radius: 30,
        backgroundColor: group.color,
        child: Text(
          group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}

class _AddGroupCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          // TODO: open add group sheet
        },
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: Icon(Icons.add, color: Colors.grey.shade500, size: 28),
          ),
        ),
      ),
    );
  }
}