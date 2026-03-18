import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/models/group.dart';
import '../shared/models/status.dart';
import '../shared/models/task.dart';
import '../shared/models/user_stats.dart';
import '../shared/services/group_task_service.dart';
import '../shared/services/stats_service.dart';
import '../shared/widgets/add_forms/add_task_form.dart';
import '../shared/widgets/task_tiles/status_checkbox.dart';
import '../shared/widgets/task_tiles/delete_confirmation_dialog.dart';
import '../shared/widgets/task_tiles/dismissible_remove_background.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.data == null) return _NotLoggedIn();
        return _GroupsList();
      },
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64,
              color: Colors.blueAccent.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Sign in to use groups',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (context, _) {
        final groups = groupTaskService.groups;
        return Column(
          children: [
            _GroupsHeader(),
            Expanded(
              child: groups.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: groups.length + 1,
                itemBuilder: (context, i) {
                  if (i == groups.length) {
                    return const SizedBox(height: 80);
                  }
                  return _GroupCard(group: groups[i]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Your Groups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => showDialog(
                context: context,
                builder: (_) => const _JoinGroupDialog()),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Join'),
          ),
          TextButton.icon(
            onPressed: () => showDialog(
                context: context,
                builder: (_) => const _CreateGroupDialog()),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 72,
              color: Colors.blueAccent.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one or join with a group ID',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final taskCount = groupTaskService.tasksForGroup(group.id).length;
    final memberCount = group.members.length;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = group.createdBy == uid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => GroupDetailPage(group: group)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
            Border(left: BorderSide(color: group.color, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: group.color.withValues(alpha: 0.2),
                child: Icon(Icons.group, color: group.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '$memberCount member${memberCount != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.task_alt,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '$taskCount task${taskCount != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy group ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: group.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group ID copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (!isOwner)
                IconButton(
                  icon: Icon(Icons.exit_to_app,
                      size: 18, color: Colors.red.shade400),
                  tooltip: 'Leave group',
                  onPressed: () => _confirmLeave(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave group'),
        content: Text('Leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              groupTaskService.leaveGroup(group.id);
              Navigator.pop(context);
            },
            child: Text('Leave',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          backgroundColor: group.color,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tasks', icon: Icon(Icons.checklist, size: 18)),
              Tab(text: 'Members', icon: Icon(Icons.leaderboard, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TasksTab(group: group),
            _LeaderboardTab(group: group),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: group.color,
          foregroundColor: Colors.white,
          onPressed: () =>
              AddTaskSheet.show(context, preselectedGroup: group),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.group});
  final Group group;

  Status _next(Status s) {
    switch (s) {
      case Status.todo:
        return Status.inProgress;
      case Status.inProgress:
        return Status.done;
      case Status.done:
        return Status.todo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (context, _) {
        final tasks = groupTaskService.tasksForGroup(group.id);

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist, size: 64,
                    color: group.color.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No tasks yet',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          itemCount: tasks.length + 1,
          itemBuilder: (context, i) {
            if (i == tasks.length) return const SizedBox(height: 80);
            final task = tasks[i];
            return _GroupDetailTaskCard(
              task: task,
              groupId: group.id,
              onStatusTap: () => groupTaskService.updateTask(
                group.id,
                task.copyWith(status: _next(task.status)),
              ),
              onDelete: () => groupTaskService.deleteTask(
                  group.id, task.id),
            );
          },
        );
      },
    );
  }
}

class _GroupDetailTaskCard extends StatelessWidget {
  const _GroupDetailTaskCard({
    required this.task,
    required this.groupId,
    required this.onStatusTap,
    required this.onDelete,
  });

  final Task task;
  final String groupId;
  final VoidCallback onStatusTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == Status.done;
    return Dismissible(
      key: Key('detail-${task.id}'),
      direction: DismissDirection.endToStart,
      background: const DismissibleRemoveBackground(
          mainAxisAlignment: MainAxisAlignment.end),
      confirmDismiss: (_) =>
          const DeleteConfirmationDialog().show(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
            Border(left: BorderSide(color: task.color, width: 4)),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              StatusCheckbox(status: task.status, onTap: onStatusTap),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration:
                        isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.category.color
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            task.category.name,
                            style: TextStyle(
                                fontSize: 10,
                                color: task.category.color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          task.formatDate(task.date),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
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

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab({required this.group});
  final Group group;

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab>
    with AutomaticKeepAliveClientMixin {
  List<UserStats>? _stats;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats =
      await statsService.fetchMembersStats(widget.group.members);
      if (mounted) setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Could not load leaderboard';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final stats = _stats ?? [];

    if (stats.isEmpty) {
      return Center(
        child: Text('No member data yet',
            style:
            TextStyle(fontSize: 16, color: Colors.grey.shade400)),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: stats.length,
        itemBuilder: (context, i) {
          final s = stats[i];
          final isMe = s.uid == uid;
          final rank = i + 1;

          Color rankColor;
          IconData? rankIcon;
          if (rank == 1) {
            rankColor = const Color(0xFFFFD700);
            rankIcon = Icons.emoji_events;
          } else if (rank == 2) {
            rankColor = const Color(0xFFC0C0C0);
            rankIcon = Icons.emoji_events;
          } else if (rank == 3) {
            rankColor = const Color(0xFFCD7F32);
            rankIcon = Icons.emoji_events;
          } else {
            rankColor = Colors.grey.shade400;
            rankIcon = null;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? widget.group.color.withValues(alpha: 0.08)
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: isMe
                  ? Border.all(
                  color:
                  widget.group.color.withValues(alpha: 0.4),
                  width: 1.5)
                  : null,
            ),
            child: ListTile(
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: s.photoUrl != null
                        ? NetworkImage(s.photoUrl!)
                        : null,
                    backgroundColor:
                    widget.group.color.withValues(alpha: 0.15),
                    child: s.photoUrl == null
                        ? Text(
                      s.displayName.isNotEmpty
                          ? s.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: widget.group.color,
                          fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  if (rankIcon != null)
                    Icon(rankIcon, size: 14, color: rankColor),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.displayName + (isMe ? ' (you)' : ''),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMe ? widget.group.color : null,
                      ),
                    ),
                  ),
                  Text(
                    UserStats.rankTitle(s.points),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  _MiniStat(
                      icon: Icons.star,
                      value: '${s.points} pts',
                      color: rankColor),
                  const SizedBox(width: 12),
                  _MiniStat(
                      icon: Icons.check_circle_outline,
                      value: '${s.tasksCompleted} done',
                      color: Colors.green),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                      fontSize: 15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() =>
      _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _ctrl = TextEditingController();
  int _color = Colors.blueAccent.toARGB32();
  bool _loading = false;

  final List<Color> _palette = [
    Colors.blueAccent,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await groupTaskService.createGroup(name, _color);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Group name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final selected = c.toARGB32() == _color;
              return GestureDetector(
                onTap: () =>
                    setState(() => _color = c.toARGB32()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                          color: c.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1)
                    ]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _create,
          child: _loading
              ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _JoinGroupDialog extends StatefulWidget {
  const _JoinGroupDialog();

  @override
  State<_JoinGroupDialog> createState() =>
      _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final id = _ctrl.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await groupTaskService.joinGroup(id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = 'Group not found. Check the ID and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Group ID',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask a group member to copy and share their group ID.',
            style:
            TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _join,
          child: _loading
              ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(strokeWidth: 2))
              : const Text('Join'),
        ),
      ],
    );
  }
}