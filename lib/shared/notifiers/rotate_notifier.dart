import 'package:flutter/material.dart';

class RotateNotifier extends ValueNotifier<bool>{
  RotateNotifier(): super(false);
  RotateNotifier.withValue(bool value) : super(value);

  void changeValue(bool value){
    this.value = value;
    notifyListeners();
  }
}