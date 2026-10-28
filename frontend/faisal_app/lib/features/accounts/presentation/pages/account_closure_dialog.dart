import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_entities.dart';
import '../cubit/accounts_cubit.dart';

/// Confirms and submits an account-closure request (staff approval required).
Future<void> requestAccountClosure(
  BuildContext context,
  Account account,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.closeAccount),
      content: Text(l10n.closeAccountWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.submit),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final cubit = sl<AccountRequestCubit>();
  String? reference;
  try {
    await cubit.submitClose(accountId: account.id);
    final state = cubit.state;
    if (state is AccountRequestSubmitted) {
      reference = state.reference;
    }
  } finally {
    await cubit.close();
  }

  if (reference != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.requestSubmittedMessage(reference))),
    );
  } else {
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnexpected)));
  }
}

/// Small reusable sheet padding helper used by transaction filters.
EdgeInsets sheetPadding(BuildContext context) => EdgeInsets.only(
  left: AppSpacing.lg,
  right: AppSpacing.lg,
  bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
  top: AppSpacing.sm,
);
