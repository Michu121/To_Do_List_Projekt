import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';
class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const MyAppBar(title: "HomePage"),
      floatingActionButton: Transform.translate(
        offset: Offset(0,-2),
            child: SizedBox(
              height: 70,
              width: 70,
            child: FloatingActionButton(
              onPressed: (){},
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightBlueAccent,
              splashColor: Colors.lightBlueAccent.shade700,
              hoverColor: Colors.lightBlueAccent.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 6,
              highlightElevation: 10,
              child : Icon(Icons.add, size: 50,),
            )
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomAppBar(),
    );
  }
}