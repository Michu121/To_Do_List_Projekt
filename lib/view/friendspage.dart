import 'package:flutter/material.dart';
import '../shared/services/friend_services.dart';
import '../shared/models/user_model.dart';
import '../shared/widgets/in_app_notification.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _StatusBadge extends StatelessWidget {
  final int count;
  const _StatusBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(6),
      decoration:
      const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    friendServices.init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addFriendDialog() {
    final theme = Theme.of(context);
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Add friend'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the email of the person you want to add.',
                style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              final error =
              await friendServices.sendRequestByEmail(email);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (error != null) {
                InAppNotification.error(context, error);
              } else {
                InAppNotification.success(
                    context, 'Friend request sent!');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent =
    accent.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    return ListenableBuilder(
      listenable: friendServices,
      builder: (context, _) {
        final requests = friendServices.getRequests();
        final all = friendServices.getFriends();
        final q = _searchCtrl.text.toLowerCase();
        final filtered = all
            .where((f) =>
        f.name.toLowerCase().contains(q) ||
            f.email.toLowerCase().contains(q))
            .toList();

        return Column(
          children: [
            // ── Search bar on accent background ────────────────
            Container(
              color: theme.appBarTheme.backgroundColor,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: onAccent),
                      decoration: InputDecoration(
                        hintText: 'Search friends…',
                        hintStyle: TextStyle(
                            color: onAccent.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.search,
                            color: onAccent.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: onAccent.withValues(alpha: 0.12),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                        onAccent.withValues(alpha: 0.15),
                        child: IconButton(
                          icon: Icon(Icons.person_add, color: onAccent),
                          onPressed: _addFriendDialog,
                          tooltip: 'Add friend',
                        ),
                      ),
                      _StatusBadge(count: requests.length),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                children: [
                  // ── Pending requests ─────────────────────────
                  if (requests.isNotEmpty) ...[
                    _SectionHeader(
                        label: 'Pending requests (${requests.length})',
                        color: Colors.orange),
                    const SizedBox(height: 6),
                    ...requests.map((r) => _RequestCard(
                      user: r,
                      onAccept: () =>
                          friendServices.acceptRequest(r),
                      onDecline: () =>
                          friendServices.declineRequest(r.uid),
                    )),
                    const Divider(height: 24),
                  ],

                  // ── Friends ────────────────────────────────
                  _SectionHeader(
                      label: 'Your friends (${all.length})',
                      color: accent),
                  const SizedBox(height: 6),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 56,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            all.isEmpty
                                ? 'No friends yet. Add someone!'
                                : 'No friends match your search.',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((f) => _FriendCard(
                      friend: f,
                      onRemove: () =>
                          friendServices.removeFriend(f.uid),
                    )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RequestCard(
      {required this.user,
        required this.onAccept,
        required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name.isNotEmpty ? user.name : 'User',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Accept',
              onPressed: onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              tooltip: 'Decline',
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend card ───────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  final UserModel friend;
  final VoidCallback onRemove;
  const _FriendCard({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final initials = friend.name.isNotEmpty
        ? friend.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : friend.email.isNotEmpty
        ? friend.email[0].toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.12),
          backgroundImage:
          friend.photo != null ? NetworkImage(friend.photo!) : null,
          child: friend.photo == null
              ? Text(initials,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(
            friend.name.isNotEmpty ? friend.name : friend.email,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: friend.name.isNotEmpty
            ? Text(friend.email,
            style: TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.55)))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Colors.redAccent),
          tooltip: 'Remove friend',
          onPressed: onRemove,
        ),
      ),
    );
  }
}