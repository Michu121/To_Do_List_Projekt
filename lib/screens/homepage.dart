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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: const MyAppBar(),
      floatingActionButton: Transform.translate(
        offset: Offset(0,-2),
            child: SizedBox(
              height: 70,
              width: 70,
            child: FloatingActionButton(
              onPressed: (){},
              child : Icon(Icons.add, size: 50,),
            )
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomAppBar(isFloating: true,activePage: AppPage.home),
    );
  }
}