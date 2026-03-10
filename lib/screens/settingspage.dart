import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';
class SettingsPage extends StatefulWidget{
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const MyAppBar(),
      bottomNavigationBar: MyBottomAppBar(activePage: AppPage.settings),
    );
  }
}