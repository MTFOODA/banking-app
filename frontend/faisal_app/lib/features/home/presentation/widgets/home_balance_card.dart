import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_balance_visibility.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_entities.dart';

class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({
    super.key,
    required this.overview,
    required this.visibility,
    required this.onAccountsTap,
  });

  final HomeOverview overview;
  final BalanceVisibilityController visibility;
  final VoidCallback onAccountsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final totals = overview.accounts.totals;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: FaisalGradients.card(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: visibility,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.totalBalance,
                  style: TextStyle(
                    color: FaisalColors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                FaisalBalanceVisibilityToggle(
                  controller: visibility,
                  showLabel: l10n.showBalance,
                  hideLabel: l10n.hideBalance,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                visibility.visible
                    ? FaisalFormatters.money(
                        totals.totalAvailable,
                        currency: totals.currency,
                        locale: locale,
                      )
                    : 'â€¢â€¢â€¢â€¢â€¢â€¢',
                style: const TextStyle(
                  color: FaisalColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: FaisalColors.goldAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.activeAccountsCount(totals.eligibleAccounts),
                    style: TextStyle(
                      color: FaisalColors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAccountsTap,
                  style: TextButton.styleFrom(
                    foregroundColor: FaisalColors.goldAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
