import 'package:flutter/material.dart';
import 'barrel.dart';
import 'package:todo_list/assets/widgets.dart';
import 'package:todo_list/l10n/app_localizations.dart';
class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Calendar"),
    );
  }
}
