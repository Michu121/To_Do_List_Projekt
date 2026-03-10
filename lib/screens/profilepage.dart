import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';
class ProfilePage extends StatefulWidget{
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const MyAppBar(),
      bottomNavigationBar: MyBottomAppBar(activePage: AppPage.profile),
    );
  }
}