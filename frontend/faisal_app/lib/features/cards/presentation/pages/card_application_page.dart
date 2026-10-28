import 'package:flutter/material.dart';

import '../../../branding/presentation/widgets/branding_scope.dart';
import '../../../branding/domain/entities/branding_config.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/labels.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/card_artwork.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../requests/domain/repositories/requests_repository.dart';
import '../../domain/entities/card_product.dart';
import '../../domain/repositories/cards_repository.dart';
import '../cubit/card_application_cubit.dart';

String cardEligibilityLabel(AppLocalizations l, String? reason) =>
    switch (reason) {
      'card_age_unverified' => l.cardAgeUnverified,
      'card_youth_age' => l.cardYouthAge,
      'card_fx_account_required' => l.cardForeignRequired,
      'card_investment_required' => l.cardInvestmentRequired,
      'card_eligible_account_required' => l.cardAccountRequired,
      _ => l.cardUnavailable,
    };

class CardApplicationPage extends StatelessWidget {
  const CardApplicationPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        CardApplicationCubit(sl<CardsRepository>(), sl<RequestsRepository>())
          ..load(),
    child: const CardApplicationView(),
  );
}

class CardApplicationView extends StatefulWidget {
  const CardApplicationView({super.key});
  @override
  State<CardApplicationView> createState() => _CardApplicationViewState();
}

class _CardApplicationViewState extends State<CardApplicationView> {
  final _reviewKey = GlobalKey();
  String? _selected;
  String? _account;
  Future<void> _review(CardProduct product, CardEligibleAccount account) async {
    final l = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.cardReviewTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name(arabic),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${account.masked} · ${account.currency}'),
              Text(
                '${l.cardAnnualFee}: ${FaisalFormatters.money(product.annualFee, currency: product.feeCurrency)}',
              ),
              const SizedBox(height: 16),
              Text(l.cardApprovalNotice),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('card_issue_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.cardSubmitRequest),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await context.read<CardApplicationCubit>().submit(product, account.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<CardApplicationCubit, CardApplicationState>(
      builder: (context, s) {
        CardProduct? selected;
        for (final product in s.products) {
          if (product.code == _selected) selected = product;
        }
        if (selected != null &&
            (!selected.eligible ||
                !selected.accounts.any((a) => a.id == _account))) {
          _account = null;
        }
        CardEligibleAccount? account;
        if (selected != null) {
          for (final candidate in selected.accounts) {
            if (candidate.id == _account) account = candidate;
          }
        }
        final cubit = context.read<CardApplicationCubit>();
        return PopScope(
          canPop: !s.busy,
          child: FaisalPage(
            title: l.cardApplyTitle,
            subtitle: l.cardApplySubtitle,
            actions: [
              IconButton(
                tooltip: l.refresh,
                onPressed: s.busy ? null : cubit.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.loading) const Center(child: CircularProgressIndicator()),
                if (s.error != null) ...[
                  Text(
                    serverErrorCode(s.error!) == 'duplicate_open_request'
                        ? l.cardRequestExists
                        : securityError(l, s.error!),
                    key: const ValueKey('card_issue_error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: s.busy ? null : cubit.load,
                    child: Text(l.retry),
                  ),
                ],
                if (s.receipt != null)
                  FaisalSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.check_circle_outline),
                        Text(l.cardRequestReceived),
                        SelectableText(
                          s.receipt!.reference,
                          key: const ValueKey('card_issue_reference'),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(l.cardBackCards),
                        ),
                      ],
                    ),
                  ),
                if (s.hasOpen)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l.cardRequestExists),
                  ),
                if (!s.loading) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth > 760
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final p in s.products)
                            SizedBox(
                              width: width,
                              child: FaisalSurface(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CardProductPreview(product: p),
                                    const SizedBox(height: 12),
                                    Text(
                                      p.variant == 'platinum_fx'
                                          ? l.cardForeignOnly
                                          : (p.investmentOnly
                                                ? l.cardInvestmentOnly
                                                : l.cardDomesticAccount),
                                    ),
                                    if (p.under21Only) Text(l.cardYouthOnly),
                                    if (!p.eligible)
                                      Text(
                                        cardEligibilityLabel(l, p.reason),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      key: ValueKey('choose_${p.variant}'),
                                      onPressed:
                                          (!p.eligible || s.busy || s.hasOpen)
                                          ? null
                                          : () {
                                              setState(() {
                                                _selected = p.code;
                                                _account = p.accounts.first.id;
                                              });
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    final target = _reviewKey
                                                        .currentContext;
                                                    if (mounted &&
                                                        target != null) {
                                                      Scrollable.ensureVisible(
                                                        target,
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 250,
                                                            ),
                                                      );
                                                    }
                                                  });
                                            },
                                      child: Text(
                                        _selected == p.code
                                            ? l.cardSelected
                                            : l.cardSelect,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (selected != null && selected.eligible && !s.hasOpen) ...[
                    const SizedBox(height: 24),
                    Text(
                      '${l.cardSelected}: ${selected.name(arabic)}',
                      key: _reviewKey,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('account_${selected.code}_$_account'),
                      initialValue: _account,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.cardChooseAccount,
                      ),
                      items: [
                        for (final a in selected.accounts)
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.masked} · ${a.currency}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: s.busy
                          ? null
                          : (v) => setState(() => _account = v),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l.cardAnnualFee}: ${FaisalFormatters.money(selected.annualFee, currency: selected.feeCurrency)}',
                    ),
                    const SizedBox(height: 12),
                    Text(l.cardApprovalNotice),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('card_issue_review'),
                      onPressed: s.busy || account == null
                          ? null
                          : () => _review(selected!, account!),
                      child: s.busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : Text(l.cardReviewTitle),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: s.busy
                        ? null
                        : () => context.push(AppRoutes.accounts),
                    child: Text(l.cardOpenAccount),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.cardMyRequests,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (s.requests.isEmpty) Text(l.cardNoRequests),
                  for (final r in s.requests)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FaisalSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(r.reference),
                            Text(
                              '${r.formData[arabic ? 'product_name_ar' : 'product_name_en'] ?? r.formData['card_product_code'] ?? ''}',
                            ),
                            Text(
                              '${r.formData['account_number_masked'] ?? ''} · ${r.formData['currency'] ?? ''}',
                            ),
                            FaisalStatusBadge(
                              label: requestStatusLabel(l, r.status),
                              tone: FaisalStatusBadge.toneForStatus(r.status),
                            ),
                            if (r.status == 'rejected' &&
                                r.decisionReason != null)
                              Text(r.decisionReason!),
                            if (r.status == 'completed')
                              Text(l.cardPendingActivation),
                          ],
                        ),
                      ),
                    ),
                  if (s.hasNext)
                    TextButton(
                      onPressed: s.busy ? null : cubit.more,
                      child: Text(l.admLoadMore),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class CardProductPreview extends StatelessWidget {
  const CardProductPreview({super.key, required this.product});
  final CardProduct product;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final bank = BrandingScope.bankOf(context);
    final primary = bank == null || bank.code == 'faisal'
        ? null
        : BrandingConfig.parseColor(bank.light['primary']!);
    final accent = bank == null || bank.code == 'faisal'
        ? null
        : BrandingConfig.parseColor(bank.light['accent']!);
    return Semantics(
      label: '${l.cardPreview}: ${product.name(ar)}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cardGradient(
              product.variant,
              primary: primary,
              accent: accent,
            ),
          ),
          child: CustomPaint(
            painter: CardArtwork(product.variant),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const FaisalLogo(size: 28, onDark: true),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          product.name(ar),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l.cardPreview,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.contactless, color: Color(0xffe3cd8b)),
                      const Spacer(),
                      Text(
                        product.network ?? '',
                        style: const TextStyle(
                          color: Color(0xffe3cd8b),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
