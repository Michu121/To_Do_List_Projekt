import 'package:flutter/material.dart';

class DismissibleRemoveBackground extends StatelessWidget {
  const DismissibleRemoveBackground({super.key, required this.mainAxisAlignment});
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            mainAxisAlignment: mainAxisAlignment,
            children: [
              const Icon(Icons.delete, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Text("Usuń", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]
        )
    );
  }
}