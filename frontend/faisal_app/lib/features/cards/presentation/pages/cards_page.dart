import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_bank_card.dart';
import '../../../../core/widgets/faisal_loading_view.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/cards_cubit.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CardsCubit>()..load(),
      child: const _CardsView(),
    );
  }
}

class _CardsView extends StatelessWidget {
  const _CardsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<CardsCubit>().load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.cardsTitle, style: context.texts.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        key: const ValueKey('request_new_card'),
                        onPressed: () async {
                          await context.push(AppRoutes.cardApplication);
                          if (context.mounted) {
                            context.read<CardsCubit>().load(silent: true);
                          }
                        },
                        icon: const Icon(Icons.add_card),
                        label: Text(l10n.cardApplyTitle),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.loading)
                        const FaisalLoadingView(lines: 2)
                      else if (state.error != null)
                        FaisalErrorView(
                          error: state.error!,
                          onRetry: () => context.read<CardsCubit>().load(),
                        )
                      else if (state.overview != null) ...[
                        if (state.overview!.creditOutstandingTotal > 0)
                          FaisalSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.outstandingBalance,
                                  style: context.texts.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  FaisalFormatters.money(
                                    state.overview!.creditOutstandingTotal,
                                    locale: locale,
                                  ),
                                  style: context.texts.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.overview!.cards.isEmpty)
                          FaisalEmptyState(
                            title: l10n.noData,
                            icon: Icons.credit_card_outlined,
                          )
                        else
                          ...state.overview!.cards.map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              child: FaisalBankCard(
                                card: card,
                                onTap: () =>
                                    context.push(AppRoutes.card(card.id)),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
