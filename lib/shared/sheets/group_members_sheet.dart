import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/user_model.dart';
import '../services/group_services.dart';

class GroupMembersSheet extends StatefulWidget {
  final Group group;

  const GroupMembersSheet({super.key, required this.group});

  static void show(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GroupMembersSheet(group: group),
    );
  }

  @override
  State<GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends State<GroupMembersSheet> {
  final TextEditingController _emailController = TextEditingController();

  List<UserModel> _members = [];
  UserModel? _foundUser;
  bool _loadingMembers = false;
  bool _searching = false;
  bool _adding = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    final members = await groupServices.getMembers(widget.group);
    if (mounted) setState(() {
      _members = members;
      _loadingMembers = false;
    });
  }

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _searching = true;
      _foundUser = null;
      _searchError = null;
    });

    final user = await groupServices.findUserByEmail(email);

    if (!mounted) return;
    setState(() {
      _searching = false;
      if (user == null) {
        _searchError = 'No user found with that email';
      } else if (widget.group.memberUids.contains(user.uid)) {
        _searchError = 'This user is already a member';
      } else {
        _foundUser = user;
      }
    });
  }

  Future<void> _addMember(UserModel user) async {
    setState(() => _adding = true);
    await groupServices.addMember(widget.group.id, user.uid);
    if (!mounted) return;
    _emailController.clear();
    setState(() {
      _adding = false;
      _foundUser = null;
      _members = [..._members, user];
    });
  }

  Future<void> _removeMember(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove ${user.name.isNotEmpty ? user.name : user.email} from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;
    await groupServices.removeMember(widget.group.id, user.uid);
    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m.uid == user.uid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              widget.group.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'Members',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // ── Search bar ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Search by email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _searchError,
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ),
              const SizedBox(width: 10),
              _searching
                  ? const SizedBox(width: 44, height: 44, child: CircularProgressIndicator())
                  : IconButton.filled(
                      onPressed: _searchUser,
                      icon: const Icon(Icons.person_search),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ],
          ),

          // ── Found user preview ──────────────────────────────────────────────
          if (_foundUser != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
              ),
              child: ListTile(
                leading: _avatar(_foundUser!),
                title: Text(_foundUser!.name.isNotEmpty ? _foundUser!.name : _foundUser!.email),
                subtitle: _foundUser!.name.isNotEmpty ? Text(_foundUser!.email) : null,
                trailing: _adding
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: () => _addMember(_foundUser!),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // ── Members list ────────────────────────────────────────────────────
          if (_loadingMembers)
            const Center(child: CircularProgressIndicator())
          else if (_members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No members yet', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final member = _members[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _avatar(member),
                    title: Text(member.name.isNotEmpty ? member.name : member.email),
                    subtitle: member.name.isNotEmpty ? Text(member.email) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeMember(member),
                      tooltip: 'Remove',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(UserModel user) {
    if (user.photo != null && user.photo!.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(user.photo!));
    }
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : user.email[0].toUpperCase();
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
