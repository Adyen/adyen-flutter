import 'package:flutter/material.dart';

class DialogBuilder {
  static Future<void> showPaymentResultDialog(
    String title,
    String message,
    BuildContext context, {
    bool popOnDismiss = true,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );

    if (popOnDismiss && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
