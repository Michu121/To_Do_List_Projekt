import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';
class FriendsPage extends StatefulWidget{
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}
class _FriendsPageState extends State<FriendsPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: const MyAppBar(),
      bottomNavigationBar: MyBottomAppBar(activePage: AppPage.friends),
    );
  }
}