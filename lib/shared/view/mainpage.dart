import 'package:flutter/material.dart';
import 'package:todo_list/shared/widgets/add_task_form.dart';
import '../models/pages.dart';
import '../widgets/bottom_app_bar.dart';
import '../widgets/floating_add_button.dart';
import '../widgets/upper_app_bar.dart';
class MainPage extends StatefulWidget{
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage>{
  Pages _activePage = Pages.home;
  void setPage(Pages page) {
    setState(() {
      _activePage = page;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const MyAppBar(),
      body: _activePage.pageWidget,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          var scale = Tween(begin: 0.0,end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack)
          );
          var offset = Tween<Offset>(begin: Offset(0,1),end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut)
          );
          return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scale,
                child: SlideTransition(position: offset, child: child),
              )
          );
        },
        child: _activePage.isFloating
            ?MyFloatingButton(onPressed: _activePage == Pages.home ? () => AddTaskSheet.show(context) : _activePage == Pages.groups ? () => AddTaskSheet.show(context) : null)
            :null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomAppBar(isFloating: _activePage.isFloating,activePage: _activePage, onPageSelected: (page) => setPage(page)),
    );
  }
}


