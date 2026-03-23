import 'package:flutter/material.dart';
import '../models/colors.dart';

class ColorServices extends ChangeNotifier {
  final Map<String,ColorsToPick> _colors = {
    "Red" : ColorsToPick(color: Colors.red, checked: false),
    "Blue" : ColorsToPick(color: Colors.blue, checked: false),
    "DarkBlue" : ColorsToPick(color: Colors.blue.shade900, checked: false),
    "Green" : ColorsToPick(color: Colors.green, checked: false),
    "DarkGreen" : ColorsToPick(color: Colors.green.shade900, checked: false),
    "Orange" : ColorsToPick(color: Colors.orange, checked: false),
    "DarkOrange" : ColorsToPick(color: Colors.orange.shade900, checked: false),
    "Purple" : ColorsToPick(color: Colors.purple, checked: false),
    "Pink" : ColorsToPick(color: Colors.pink, checked: false),
    "Brown" : ColorsToPick(color: Colors.brown, checked: false),
    "Yellow" : ColorsToPick(color: Colors.yellow, checked: false),
    "Grey" : ColorsToPick(color: Colors.grey, checked: false),
  };

  Map<String,ColorsToPick> getColors() => _colors;

  void updateColor(String name, bool checked) {
    _colors.updateAll((key, currentValue) => ColorsToPick(
      color: currentValue.color,
      checked: key == name ? checked : false,
    ));
    notifyListeners();
  }

}
final ColorServices colorServices = ColorServices();