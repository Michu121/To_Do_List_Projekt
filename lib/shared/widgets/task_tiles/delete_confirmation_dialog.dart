import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DeleteConfirmationDialog {
  const DeleteConfirmationDialog();

  Future<bool?> show(BuildContext context) {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t?.delete ?? 'Delete task'),
          content: Text(t?.deleteTaskConfirm ??
              'Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t?.no ?? 'No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(t?.yes ?? 'Yes'),
            ),
          ],
        );
      },
    );
  }
}