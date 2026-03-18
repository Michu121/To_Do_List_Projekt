import 'package:flutter/material.dart';
import '../shared/services/friend_services.dart';
import '../shared/models/user_model.dart';
import 'package:uuid/uuid.dart';

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
  final Uuid _uuid = const Uuid();

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
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Wyślij zaproszenie"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Imię"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            const Text(
              "Dla celów testowych, to 'wyśle' zaproszenie, które pojawi się w sekcji oczekujące",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                // Simulating receiving a request for prototype purposes
                friendServices.receiveRequest(UserModel(
                  uid: _uuid.v4(),
                  name: nameController.text,
                  email: emailController.text,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Zaproszenie wysłane")),
                );
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
                      style: TextStyle(color: Colors.blueAccent,),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Szukaj znajomych...",
                        hintStyle: TextStyle(color: Colors.blueAccent),
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
                          backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                          child: Text(req.name[0].toUpperCase(), style: const TextStyle(color: Colors.orange)),
                        ),
                        title: Text(req.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            Icon(Icons.people_outline, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
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
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                        child: Text(friend.name[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent,)),
                      subtitle: Text(friend.email, style: const TextStyle(color: Colors.blueAccent,)),
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
