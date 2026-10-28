import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import 'open_account_sheet.dart';

class AccountServicesSection extends StatelessWidget {
  const AccountServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FaisalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FaisalPrimaryButton(
            label: l10n.openAccount,
            icon: Icons.add_card_outlined,
            onPressed: () => showOpenAccountSheet(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          FaisalSecondaryButton(
            label: l10n.requests,
            icon: Icons.assignment_outlined,
            onPressed: () => context.push(AppRoutes.requests),
          ),
        ],
      ),
    );
  }
}
