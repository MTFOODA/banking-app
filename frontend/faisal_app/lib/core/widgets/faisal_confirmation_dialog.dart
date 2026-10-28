import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/faisal_palette.dart';

/// Shared confirmation dialog for sensitive actions.
Future<bool> showFaisalConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? context.palette.danger : null,
          ),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

class FaisalConfirmationDialog extends StatelessWidget {
  const FaisalConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String? confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? context.palette.danger : null,
          ),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    );
  }
}
