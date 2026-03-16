import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width - 110,
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: monospace ? 'monospace' : null,
                    fontSize: monospace ? 11 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}