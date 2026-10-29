import 'package:flutter/material.dart';

import '../../../../core/theme/faisal_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_rows.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../../../features/authentication/presentation/bloc/auth_event.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: FaisalAppBar(title: l10n.more, showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FaisalSurface(
                    child: Column(
                      children: [
                        FaisalActionTile(
                          icon: Icons.account_balance_outlined,
                          title: l10n.savedBanksTitle,
                          onTap: () => context.read<AuthBloc>().add(
                            const AuthReturnToBanksRequested(),
                          ),
                        ),
                        FaisalActionTile(
                          icon: Icons.savings_outlined,
                          title: l10n.certificatesTitle,
                          onTap: () =>
                              context.go(AppRoutes.accountCertificates),
                        ),
                        FaisalActionTile(
                          icon: Icons.trending_up,
                          title: l10n.investmentFundsTitle,
                          onTap: () => context.go(AppRoutes.accountFunds),
                        ),
                        FaisalActionTile(
                          icon: Icons.currency_exchange,
                          title: l10n.exchangeRatesTitle,
                          onTap: () => context.push(AppRoutes.exchangeRates),
                        ),
                        FaisalActionTile(
                          icon: Icons.person_outline,
                          title: l10n.profileTitle,
                          onTap: () => context.push(AppRoutes.profile),
                        ),
                        FaisalActionTile(
                          icon: Icons.swap_horiz,
                          title: l10n.transfersTitle,
                          onTap: () => context.push(AppRoutes.transfers),
                        ),
                        FaisalActionTile(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.transactionsTitle,
                          onTap: () => context.push(AppRoutes.transactions),
                        ),
                        FaisalActionTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: l10n.accounts,
                          onTap: () => context.go(AppRoutes.accounts),
                        ),
                        FaisalActionTile(
                          icon: Icons.credit_card_outlined,
                          title: l10n.cards,
                          onTap: () => context.go(AppRoutes.cards),
                        ),
                        FaisalActionTile(
                          icon: Icons.logout,
                          title: l10n.signOut,
                          danger: true,
                          onTap: () => context.read<AuthBloc>().add(
                            const AuthLogoutRequested(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.demoDataNotice,
                    textAlign: TextAlign.center,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
