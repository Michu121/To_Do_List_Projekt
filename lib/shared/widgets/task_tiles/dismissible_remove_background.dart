import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DismissibleRemoveBackground extends StatelessWidget {
  const DismissibleRemoveBackground({
    super.key,
    required this.mainAxisAlignment,
  });

  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          Text(
            t?.delete ?? 'Delete',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}