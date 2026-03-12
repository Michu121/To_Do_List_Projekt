import 'package:flutter/material.dart';

class MyFloatingButton extends StatefulWidget{
  final dynamic onPressed;
  const MyFloatingButton({super.key, required this.onPressed});
  @override
  State<MyFloatingButton> createState() => _MyFloatingButtonState();
}
class _MyFloatingButtonState extends State<MyFloatingButton>{
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(0,-2),
        child: SizedBox(
            height: 60,
            width: 60,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              child : Icon(Icons.add, size: 50,),
            )
        )
    );
  }
}