import 'package:flutter/material.dart';
import '../shared/services/friend_services.dart';
import '../shared/models/user_model.dart';

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
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    friendServices.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addFriendDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dodaj znajomego"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Wpisz adres email osoby, którą chcesz dodać do znajomych."),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final error = await friendServices.sendRequestByEmail(email);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? "Zaproszenie zostało wysłane!")),
                  );
                }
              }
            },
            child: const Text("Wyślij"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: friendServices,
      builder: (context, _) {
        final requests = friendServices.getRequests();
        final allFriends = friendServices.getFriends();
        final filteredFriends = allFriends.where((f) => 
          f.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          f.email.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.blueAccent),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Szukaj w swoich znajomych...",
                        hintStyle: const TextStyle(color: Colors.blueAccent),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          onPressed: _addFriendDialog,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (requests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Oczekujące zaproszenia",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    ...requests.map((req) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                          child: Text(req.name.isNotEmpty ? req.name[0].toUpperCase() : "?", 
                            style: const TextStyle(color: Colors.orange)),
                        ),
                        title: Text(req.name.isNotEmpty ? req.name : "Użytkownik", 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(req.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => friendServices.acceptRequest(req),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () => friendServices.declineRequest(req.uid),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const Divider(height: 32),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Twoi znajomi",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  if (filteredFriends.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 60, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              allFriends.isEmpty ? "Nie masz jeszcze znajomych." : "Nie znaleziono znajomych.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredFriends.map((friend) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        child: Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?", 
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(friend.name.isNotEmpty ? friend.name : "Użytkownik", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      subtitle: Text(friend.email, style: const TextStyle(color: Colors.blueAccent)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => friendServices.removeFriend(friend.uid),
                      ),
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
