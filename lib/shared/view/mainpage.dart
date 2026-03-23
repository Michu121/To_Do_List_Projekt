import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/shared/services/group_task_service.dart';
import '../widgets/add_forms/add_group_form.dart';
import '../widgets/add_forms/add_task_form.dart';
import '../models/pages.dart';
import '../widgets/app_bars/bottom_app_bar.dart';
import '../widgets/floating_add_button.dart';
import '../widgets/app_bars/upper_app_bar.dart';
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Pages _activePage = Pages.home;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        groupTaskService.init();
      } else {
        groupTaskService.reset();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void setPage(Pages page) {
    setState(() => _activePage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const MyAppBar(title: '',),
      body: _activePage.pageWidget,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final scale = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );
          final offset = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: scale,
              child: SlideTransition(position: offset, child: child),
            ),
          );
        },
        child: _activePage.isFloating
            ? _activePage == Pages.home ?MyFloatingButton(onPressed: () => AddTaskSheet.show(context))
            : _activePage == Pages.groups? MyFloatingButton(onPressed: () => GroupActionsOverlay.show(context))
            :null : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomAppBar(
        isFloating: _activePage.isFloating,
        activePage: _activePage,
        onPageSelected: setPage,
      ),
    );
  }
}
