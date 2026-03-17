import 'package:flutter/material.dart';

import '../../models/colors.dart';

class ColorButton extends StatelessWidget {
  const ColorButton({super.key, required this.color, required this.onTap});

  final ColorsToPick color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // Zwiększamy obszar trafienia (hit test), żeby łatwiej było kliknąć
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(3.0), // Odstęp między przyciskami
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 35, // Większy rozmiar dla wygody użytkownika
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.color,
            border: Border.all(
              // Jeśli zaznaczony, dajemy czarną ramkę, jeśli nie - szarą
              color: color.checked ? Colors.black : Colors.grey.shade300,
              width: color.checked ? 2 : 1,
            ),
            boxShadow: color.checked
                ? [BoxShadow(color: color.color.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)]
                : [],
          ),
          child: color.checked
              ? const Icon(
            Icons.check,
            size: 18,
            color: Colors.white, // Upewnij się, że kolor ikony kontrastuje
          )
              : null,
        ),
      ),
    );
  }
}