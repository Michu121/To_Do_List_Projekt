import 'package:flutter/material.dart';

import '../../models/colors.dart';
import '../../services/color_services.dart';
import 'color_button.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.onTap, required this.selectedColor, required this.colorServices});
  final void Function(String) onTap;
  final ColorServices colorServices;
  final ColorsToPick? selectedColor;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  @override
  Widget build(BuildContext context) {
    // Pobieramy mapę kolorów
    final colorsMap = widget.colorServices.getColors();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          direction: Axis.horizontal,
          children: [
                ...colorsMap.entries.map((entry) {
                final String name = entry.key;
                final ColorsToPick colorData = entry.value;
                return ColorButton(
                  color: colorData,
                  onTap: () => widget.onTap(name), // Teraz poprawnie wywołujemy funkcję z nazwą
                );}).toList(),
          ],
        ),
        ]
      ),
    );
  }
}