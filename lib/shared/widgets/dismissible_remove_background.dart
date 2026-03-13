import 'package:flutter/material.dart';

class DismissibleRemoveBackground extends StatelessWidget {
  const DismissibleRemoveBackground({super.key, required this.mainAxisAlignment});
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      // USUNIĘTO MARGINES - tło musi wypełnić obszar wyznaczony przez Padding rodzica
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            mainAxisAlignment: mainAxisAlignment,
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 8),
              const Text("Usuń", style: TextStyle(color: Colors.white, fontSize: 20)),
            ]
        )
    );
  }
}