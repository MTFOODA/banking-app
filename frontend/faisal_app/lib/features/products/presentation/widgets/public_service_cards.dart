import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../l10n/app_localizations.dart';

class PublicServiceCards extends StatelessWidget {
  const PublicServiceCards({super.key, this.includeLogin = true});
  final bool includeLogin;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final custom = BrandingScope.of(context).customTheme;
    final cards = [
      if (includeLogin)
        (
          key: 'notice_continue_login',
          title: l.signIn,
          hint: l.publicSignInHint,
          icon: Icons.login_rounded,
          route: AppRoutes.login,
        ),
      (
        key: 'public_branches',
        title: l.publicBranches,
        hint: l.publicBranchesHint,
        icon: Icons.account_balance_outlined,
        route: AppRoutes.branches,
      ),
      (
        key: 'public_atms',
        title: l.publicAtms,
        hint: l.publicAtmsHint,
        icon: Icons.local_atm_outlined,
        route: AppRoutes.atms,
      ),
      (
        key: 'public_call_center',
        title: l.publicCallCenter,
        hint: l.publicCallCenterHint,
        icon: Icons.headset_mic_outlined,
        route: AppRoutes.callCenter,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < cards.length; i++)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  child: Material(
                    key: ValueKey(cards[i].key),
                    color: cards[i].key == 'notice_continue_login'
                        ? (custom
                              ? context.colors.primary
                              : FaisalColors.primaryGreen)
                        : (custom
                              ? context.colors.surface
                              : FaisalColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: cards[i].key == 'notice_continue_login'
                            ? (custom
                                  ? context.palette.gold
                                  : FaisalColors.goldAccent)
                            : (custom
                                  ? context.colors.outline
                                  : FaisalColors.border),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(cards[i].route),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 168),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                cards[i].icon,
                                size: 32,
                                color: cards[i].key == 'notice_continue_login'
                                    ? (custom
                                          ? context.palette.gold
                                          : FaisalColors.goldAccent)
                                    : (custom
                                          ? context.colors.primary
                                          : FaisalColors.primaryGreen),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                cards[i].title,
                                style: context.texts.titleMedium?.copyWith(
                                  color: cards[i].key == 'notice_continue_login'
                                      ? (custom
                                            ? context.colors.onPrimary
                                            : FaisalColors.white)
                                      : (custom
                                            ? context.colors.onSurface
                                            : FaisalColors.primaryText),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cards[i].hint,
                                style: context.texts.bodySmall?.copyWith(
                                  color: cards[i].key == 'notice_continue_login'
                                      ? (custom
                                            ? context.colors.onPrimary
                                            : FaisalColors.white)
                                      : (custom
                                            ? context.colors.primary
                                            : FaisalColors.primaryGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
