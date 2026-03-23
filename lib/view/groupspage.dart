import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../shared/models/group.dart';
import '../shared/models/status.dart';
import '../shared/models/task.dart';
import '../shared/models/user_model.dart';
import '../shared/services/fire_store_service.dart';
import '../shared/services/group_task_service.dart';
import '../shared/widgets/add_forms/add_task_form.dart';
import '../shared/widgets/in_app_notification.dart';
import '../shared/widgets/task_tiles/delete_confirmation_dialog.dart';
import '../shared/widgets/task_tiles/dismissible_remove_background.dart';
import '../shared/widgets/task_tiles/status_checkbox.dart';

// ─────────────────────────────────────────────────────────────────────────────

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.data == null) return const _NotLoggedIn();
        return const _GroupsList();
      },
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Sign in to use groups',
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (context, _) {
        final groups = groupTaskService.groups;
        if (groups.isEmpty) return const _EmptyState();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length + 1,
          itemBuilder: (context, i) {
            if (i == groups.length) return const SizedBox(height: 80);
            return _GroupCard(group: groups[i]);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.18)),
          const SizedBox(height: 20),
          Text('No groups yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45))),
          const SizedBox(height: 8),
          Text('Create one or join with a code / QR',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final taskCount = groupTaskService.tasksForGroup(group.id).length;
    final memberCount = group.members.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => GroupDetailPage(group: group))),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: group.color, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 13,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '$memberCount member${memberCount != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.task_alt,
                            size: 13,
                            color: Colors.grey.shade500),
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
              GestureDetector(
                onTap: () => _showQr(context),
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: group.id));
                  InAppNotification.success(context, 'Group ID copied');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.qr_code, color: group.color, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQr(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GroupQrSheet(group: group),
    );
  }
}

// ── QR sheet ──────────────────────────────────────────────────────────────────

class _GroupQrSheet extends StatelessWidget {
  const _GroupQrSheet({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Invite to ${group.name}',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Scan or share to join',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: group.color.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
            ),
            child: QrImageView(
              data: group.id,
              version: QrVersions.auto,
              size: 220,
              eyeStyle:
              QrEyeStyle(eyeShape: QrEyeShape.square, color: group.color),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: group.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(group.id,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: group.id));
                    Navigator.pop(context);
                    InAppNotification.success(context, 'Group ID copied');
                  },
                  child: Icon(Icons.copy, size: 16, color: group.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group detail page ─────────────────────────────────────────────────────────

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
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _GroupQrSheet(group: group),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tasks', icon: Icon(Icons.checklist, size: 18)),
              Tab(text: 'Members', icon: Icon(Icons.people, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TasksTab(group: group),
            _MembersTab(groupId: group.id),
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

// ── Tasks tab ─────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.group});
  final Group group;

  Status _next(Status s) => switch (s) {
    Status.todo => Status.inProgress,
    Status.inProgress => Status.done,
    Status.done => Status.todo,
  };

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
                Icon(Icons.checklist,
                    size: 64,
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
                  group.id, task.copyWith(status: _next(task.status))),
              onDelete: () =>
                  groupTaskService.deleteTask(group.id, task.id),
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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
              Border(left: BorderSide(color: task.color, width: 4))),
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
                    Text(task.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : null)),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(task.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
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
                          child: Text(task.category.name,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: task.category.color,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(task.formatDate(task.date),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
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

// ── Members tab ───────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  const _MembersTab({required this.groupId});
  final String groupId;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab>
    with AutomaticKeepAliveClientMixin {
  final Map<String, UserModel> _cache = {};
  List<UserModel> _members = [];
  bool _loading = true;
  List<String> _lastUids = [];

  @override
  bool get wantKeepAlive => true;

  Group? _liveGroup() {
    try {
      return groupTaskService.groups
          .firstWhere((g) => g.id == widget.groupId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    groupTaskService.addListener(_onServiceChange);
    _fetchMembers();
  }

  @override
  void dispose() {
    groupTaskService.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() {
    final g = _liveGroup();
    if (g == null) return;
    final cur = List<String>.from(g.members)..sort();
    final last = List<String>.from(_lastUids)..sort();
    if (cur.toString() != last.toString()) _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final g = _liveGroup();
    if (g == null) return;
    if (mounted) setState(() => _loading = true);
    _lastUids = List.from(g.members);

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final results = await Future.wait(g.members.map((uid) async {
      if (_cache.containsKey(uid)) return _cache[uid]!;
      try {
        final u = await firestoreService.getUserById(uid);
        if (u != null) {
          _cache[uid] = u;
          return u;
        }
      } catch (_) {}
      final stub = UserModel(
        uid: uid,
        email: uid == myUid
            ? (FirebaseAuth.instance.currentUser?.email ?? '')
            : '',
        name: uid == myUid
            ? (FirebaseAuth.instance.currentUser?.displayName ?? '')
            : 'Member',
        photo: uid == myUid
            ? FirebaseAuth.instance.currentUser?.photoURL
            : null,
      );
      _cache[uid] = stub;
      return stub;
    }));

    if (mounted) {
      setState(() {
        _members = results.whereType<UserModel>().toList();
        _loading = false;
      });
    }
  }

  void _confirmRemove(BuildContext context, Group g, UserModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member'),
        content: Text(
            'Remove ${m.name.isNotEmpty ? m.name : m.email} from the group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              groupTaskService.removeMember(g.id, m.uid);
              _cache.remove(m.uid);
            },
            child:
            Text('Remove', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, Group g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave group'),
        content: Text('Leave "${g.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              groupTaskService.leaveGroup(g.id);
              Navigator.of(context).pop();
            },
            child:
            Text('Leave', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Group g) {
    final ctrl = TextEditingController();
    String? err;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Delete group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(ctx).style,
                  children: [
                    const TextSpan(text: 'This will permanently delete '),
                    TextSpan(
                        text: g.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                        ' and all its tasks.\n\nType the group name to confirm:'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: g.name,
                    border: const OutlineInputBorder(),
                    errorText: err),
                onChanged: (_) {
                  if (err != null) setSt(() => err = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim() != g.name) {
                  setSt(() => err = 'Name does not match');
                  return;
                }
                Navigator.pop(ctx);
                Navigator.of(context).pop();
                groupTaskService.deleteGroup(g.id);
              },
              child: Text('Delete',
                  style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (context, _) {
        final g = _liveGroup();
        if (g == null) {
          return const Center(child: Text('Group not found'));
        }
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        final isOwner = g.createdBy == myUid;

        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _fetchMembers,
          child: ListView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                '${_members.length} member${_members.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._members.map((m) {
                final isMe = m.uid == myUid;
                final isCreator = m.uid == g.createdBy;
                final initials = m.name.isNotEmpty
                    ? m.name
                    .trim()
                    .split(' ')
                    .map((p) => p[0])
                    .take(2)
                    .join()
                    .toUpperCase()
                    : m.email.isNotEmpty
                    ? m.email[0].toUpperCase()
                    : '?';

                final subtitleParts = [
                  if (isCreator) 'Creator',
                  if (isMe) 'You',
                ];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: isMe ? 2 : 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      g.color.withValues(alpha: 0.15),
                      child: m.photo != null
                          ? ClipOval(
                          child: Image.network(m.photo!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover))
                          : Text(initials,
                          style: TextStyle(
                              color: g.color,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                        m.name.isNotEmpty ? m.name : m.email,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: subtitleParts.isNotEmpty
                        ? Text(subtitleParts.join(' · '),
                        style: TextStyle(
                            fontSize: 11,
                            color: isCreator
                                ? g.color
                                : Colors.grey.shade500,
                            fontWeight: isCreator
                                ? FontWeight.w600
                                : FontWeight.normal))
                        : null,
                    trailing: isOwner && !isCreator
                        ? IconButton(
                      icon: Icon(Icons.person_remove,
                          size: 18, color: Colors.red.shade400),
                      tooltip: 'Remove member',
                      onPressed: () =>
                          _confirmRemove(context, g, m),
                    )
                        : (!isOwner && isMe)
                        ? TextButton(
                      onPressed: () =>
                          _confirmLeave(context, g),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400),
                      child: const Text('Leave'),
                    )
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (isOwner)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, g),
                    icon: Icon(Icons.delete_forever,
                        color: Colors.red.shade600),
                    label: Text('Delete group',
                        style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}