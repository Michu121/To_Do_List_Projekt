import 'package:flutter/material.dart';

class DeleteConfirmationDialog {
  const DeleteConfirmationDialog();

  // Zmieniono na Future<bool?>, aby obsłużyć asynchroniczność showDialog
  Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Usuń zadanie"),
          content: const Text("Czy na pewno chcesz usunąć zadanie?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Nie"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Tak"),
            ),
          ],
        );
      },
    );
  }
}