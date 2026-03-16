import 'package:flutter/material.dart';

import '../shared/models/group.dart';
import '../shared/services/group_services.dart';
import '../shared/sheets/group_members_sheet.dart';


class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: groupServices,
      builder: (context, _) {
        final groups = groupServices.getGroups();

        if (groups.isEmpty) {
          return Center(
            child: Text(
              'No groups yet',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: groups.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return _GroupTile(group: groups[index]);
          },
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Group group;

  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final memberCount = group.memberUids.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: group.color,
          radius: 22,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(
          memberCount == 0
              ? 'No members'
              : memberCount == 1
              ? '1 member'
              : '$memberCount members',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.group_add),
          tooltip: 'Manage members',
          color: Colors.blueAccent,
          onPressed: () => GroupMembersSheet.show(context, group),
        ),
      ),
    );
  }
}