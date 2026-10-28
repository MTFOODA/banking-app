import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/labels.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_bank_card.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_confirmation_dialog.dart';
import '../../../../core/widgets/faisal_loading_view.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_rows.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/cards_repository.dart';
import '../cubit/card_details_cubit.dart';

class CardDetailsPage extends StatelessWidget {
  const CardDetailsPage({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CardDetailsCubit>(param1: cardId)..load(),
      child: const _CardDetailsView(),
    );
  }
}

class _CardDetailsView extends StatelessWidget {
  const _CardDetailsView();

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function() action,
    required String successMessage,
    bool destructive = false,
  }) async {
    final confirmed = await showFaisalConfirmation(
      context,
      title: title,
      message: message,
      destructive: destructive,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    // ignore: use_build_context_synchronously
    final l10n = AppLocalizations.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? successMessage : l10n.cardActionFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BlocConsumer<CardDetailsCubit, CardDetailsState>(
      listenWhen: (previous, current) =>
          previous.lastReference != current.lastReference,
      listener: (context, state) {
        if (state.lastReference != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.requestSubmittedMessage(state.lastReference!)),
            ),
          );
        }
      },
      builder: (context, state) {
        final card = state.card;
        return Scaffold(
          appBar: FaisalAppBar(
            title: card == null
                ? l10n.cardSettings
                : l10n.cardEndingIn(card.last4),
            actions: [
              if (card != null)
                IconButton(
                  tooltip: l10n.refresh,
                  onPressed: () => context.read<CardDetailsCubit>().load(),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: state.loading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: FaisalLoadingView(lines: 3),
                )
              : state.error != null
              ? FaisalErrorView(
                  error: state.error!,
                  onRetry: () => context.read<CardDetailsCubit>().load(),
                )
              : card == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FaisalBankCard(card: card),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                FaisalStatusBadge(
                                  label: cardStatusLabel(l10n, card.status),
                                  tone: FaisalStatusBadge.toneForStatus(
                                    card.status,
                                  ),
                                ),
                                const Spacer(),
                                if (card.isSupplementary)
                                  Chip(label: Text(l10n.supplementaryCard)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (card.isCredit) ...[
                              FaisalSurface(
                                child: Column(
                                  children: [
                                    FaisalInfoRow(
                                      label: l10n.outstandingBalance,
                                      value: FaisalFormatters.money(
                                        card.outstandingBalance ?? 0,
                                        locale: locale,
                                      ),
                                    ),
                                    FaisalInfoRow(
                                      label: l10n.statementBalance,
                                      value: FaisalFormatters.money(
                                        card.statementBalance ?? 0,
                                        locale: locale,
                                      ),
                                    ),
                                    FaisalInfoRow(
                                      label: l10n.minimumPayment,
                                      value: FaisalFormatters.money(
                                        card.minimumPayment ?? 0,
                                        locale: locale,
                                      ),
                                    ),
                                    FaisalInfoRow(
                                      label: l10n.creditLimit,
                                      value: FaisalFormatters.money(
                                        card.creditLimit ?? 0,
                                        locale: locale,
                                      ),
                                    ),
                                    FaisalInfoRow(
                                      label: l10n.availableCredit,
                                      value: FaisalFormatters.money(
                                        card.availableCredit ?? 0,
                                        locale: locale,
                                      ),
                                    ),
                                    FaisalInfoRow(
                                      label: l10n.paymentDueDate,
                                      value: card.paymentDueDate == null
                                          ? 'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â'
                                          : FaisalFormatters.date(
                                              card.paymentDueDate!,
                                              locale: locale,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FaisalPrimaryButton(
                                label: l10n.repayCreditCard,
                                onPressed: () =>
                                    context.push(AppRoutes.repayments),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            FaisalSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.cardSettings,
                                    style: context.texts.titleSmall,
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      l10n.onlinePayments,
                                      style: context.texts.bodyMedium,
                                    ),
                                    value: card.limits?.onlineEnabled ?? false,
                                    onChanged: (value) => context
                                        .read<CardDetailsCubit>()
                                        .toggleControl('online', value),
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      l10n.internationalPayments,
                                      style: context.texts.bodyMedium,
                                    ),
                                    value:
                                        card.limits?.internationalEnabled ??
                                        false,
                                    onChanged: (value) => context
                                        .read<CardDetailsCubit>()
                                        .toggleControl('international', value),
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      l10n.contactlessPayments,
                                      style: context.texts.bodyMedium,
                                    ),
                                    value:
                                        card.limits?.contactlessEnabled ??
                                        false,
                                    onChanged: (value) => context
                                        .read<CardDetailsCubit>()
                                        .toggleControl('contactless', value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FaisalSurface(
                              child: Column(
                                children: [
                                  FaisalInfoRow(
                                    label: l10n.dailyPurchaseLimit,
                                    value: FaisalFormatters.money(
                                      card.limits?.dailyPurchaseLimit ?? 0,
                                      locale: locale,
                                    ),
                                  ),
                                  FaisalInfoRow(
                                    label: l10n.dailyAtmLimit,
                                    value: FaisalFormatters.money(
                                      card.limits?.dailyAtmLimit ?? 0,
                                      locale: locale,
                                    ),
                                  ),
                                  FaisalInfoRow(
                                    label: l10n.monthlyLimit,
                                    value: FaisalFormatters.money(
                                      card.limits?.monthlyLimit ?? 0,
                                      locale: locale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            FaisalSecondaryButton(
                              label: l10n.transactionsTitle,
                              icon: Icons.receipt_long_outlined,
                              onPressed: () => context.push(
                                AppRoutes.cardTransactionHistory(card.id),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (card.isFrozen)
                              FaisalPrimaryButton(
                                label: l10n.unfreezeCard,
                                icon: Icons.lock_open_outlined,
                                onPressed: () => _confirmAction(
                                  context,
                                  title: l10n.confirmUnfreezeTitle,
                                  message: l10n.confirmUnfreezeBody,
                                  action: () => context
                                      .read<CardDetailsCubit>()
                                      .unfreeze(),
                                  successMessage: l10n.cardUnfrozenSuccess,
                                ),
                              )
                            else if (card.isActive)
                              FaisalSecondaryButton(
                                label: l10n.freezeCard,
                                icon: Icons.ac_unit_outlined,
                                onPressed: () => _confirmAction(
                                  context,
                                  title: l10n.confirmFreezeTitle,
                                  message: l10n.confirmFreezeBody,
                                  action: () =>
                                      context.read<CardDetailsCubit>().freeze(),
                                  successMessage: l10n.cardFrozenSuccess,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            FaisalSecondaryButton(
                              label: l10n.reportLostCard,
                              icon: Icons.report_gmailerrorred_outlined,
                              destructive: true,
                              onPressed: () => _confirmAction(
                                context,
                                title: l10n.confirmLostTitle,
                                message: l10n.confirmLostBody,
                                action: () => context
                                    .read<CardDetailsCubit>()
                                    .reportLost('lost'),
                                successMessage: l10n.cardBlockedSuccess,
                                destructive: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FaisalSecondaryButton(
                              label: l10n.requestReplacement,
                              icon: Icons.autorenew,
                              onPressed: () => context
                                  .read<CardDetailsCubit>()
                                  .submitRequest(
                                    () => sl<CardsRepository>()
                                        .requestReplacement(
                                          card.id,
                                          reason: l10n.requestReplacement,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FaisalSecondaryButton(
                              label: l10n.blockCardPermanently,
                              icon: Icons.block,
                              destructive: true,
                              onPressed: () => _confirmAction(
                                context,
                                title: l10n.confirmBlockTitle,
                                message: l10n.confirmBlockBody,
                                action: () =>
                                    context.read<CardDetailsCubit>().block(),
                                successMessage: l10n.cardBlockedSuccess,
                                destructive: true,
                              ),
                            ),
                            if (state.actionError != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.cardActionFailed,
                                style: TextStyle(color: context.palette.danger),
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
