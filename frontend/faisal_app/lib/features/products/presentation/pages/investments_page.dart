import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../core/utils/money_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../../authentication/presentation/pages/authorization_page.dart';
import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';
import '../cubit/investments_cubit.dart';

class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({
    super.key,
    this.productType = 'certificate',
    this.embedded = false,
  });
  final String productType;
  final bool embedded;
  @override
  State<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage> {
  late final _cubit = InvestmentsCubit(
    sl<InvestmentRepository>(),
    sl<AccountsRepository>(),
    productType: widget.productType,
  )..load();
  final _amount = TextEditingController(), _token = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _product, _account;
  bool _confirmed = false;
  @override
  void dispose() {
    _cubit.close();
    _amount.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.productType == 'fund'
        ? l.investmentFundsTitle
        : l.certificatesTitle;
    final body = BlocBuilder<InvestmentsCubit, InvestmentsState>(
      bloc: _cubit,
      builder: (context, s) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FaisalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.embedded) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(l.investmentSimulationNotice),
                  const SizedBox(height: 16),
                  if (s.busy) const LinearProgressIndicator(),
                  if (s.error != null) ...[
                    Text(
                      securityError(l, s.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (s.quote == null)
                      TextButton(
                        onPressed: s.busy ? null : _cubit.load,
                        child: Text(l.retry),
                      ),
                  ],
                  if (s.receipt != null)
                    ..._receipt(s.receipt!, ar)
                  else if (s.quote != null)
                    ..._review(s, ar)
                  else ...[
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            key: const ValueKey('investment_product'),
                            isExpanded: true,
                            initialValue: _product,
                            decoration: InputDecoration(labelText: title),
                            items: s.products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.name(ar),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: s.busy
                                ? null
                                : (v) => setState(() => _product = v),
                            validator: (v) =>
                                v == null ? l.fieldRequired : null,
                          ),
                          if (_product != null) ...[
                            const SizedBox(height: 12),
                            _terms(
                              s.products.firstWhere((p) => p.id == _product),
                            ),
                          ],
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: const ValueKey('investment_account'),
                            isExpanded: true,
                            initialValue: _account,
                            decoration: InputDecoration(
                              labelText: l.fromAccount,
                            ),
                            items: s.accounts
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(
                                      '${a.accountNumberMasked} • ${a.currency}',
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                v == null ? l.fieldRequired : null,
                            onChanged: s.busy
                                ? null
                                : (v) => setState(() => _account = v),
                          ),
                          if (_account != null)
                            Text(
                              '${l.availableBalance}: ${s.accounts.firstWhere((a) => a.id == _account).availableBalance.toStringAsFixed(2)} EGP',
                            ),
                          const SizedBox(height: 16),
                          FaisalTextField(
                            controller: _amount,
                            label: '${l.amount} (EGP)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [MoneyInputFormatter()],
                            validator: (v) {
                              final amount = double.tryParse(
                                normalizeMoney(v ?? ''),
                              );
                              if (amount == null || amount <= 0) {
                                return l.amountPositive;
                              }
                              if (_product != null) {
                                final p = s.products.firstWhere(
                                  (p) => p.id == _product,
                                );
                                final cents = (amount * 100).round();
                                final step =
                                    (double.parse(p.text('amount_step')) * 100)
                                        .round();
                                if (amount <
                                        double.parse(
                                          p.text('minimum_amount'),
                                        ) ||
                                    cents % step != 0) {
                                  return l.investmentAmountError;
                                }
                              }
                              if (_account != null &&
                                  amount >
                                      s.accounts
                                          .firstWhere((a) => a.id == _account)
                                          .availableBalance) {
                                return l.insufficientFunds;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FaisalPrimaryButton(
                            label: l.investmentSubscribe,
                            loading: s.busy,
                            onPressed: s.busy
                                ? null
                                : () {
                                    if (_form.currentState!.validate()) {
                                      _resetToken();
                                      _cubit.review({
                                        'action': 'subscribe',
                                        'product_id': _product,
                                        'account_id': _account,
                                        'amount': normalizeMoney(_amount.text),
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      widget.productType == 'fund'
                          ? l.myFunds
                          : l.myCertificates,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (s.holdings.isEmpty && !s.busy) Text(l.noInvestments),
                    for (final h in s.holdings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  h.name(ar),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  '${l.investmentPrincipal}: ${h.text('principal')} EGP',
                                ),
                                Text(
                                  '${l.investmentUnits}: ${h.text('units')}',
                                ),
                                Text(
                                  h.active
                                      ? l.investmentActive
                                      : l.investmentRedeemed,
                                ),
                                if (h.text('matures_at').isNotEmpty)
                                  Text(
                                    '${l.investmentMaturity}: ${_date(h.text('matures_at'))}',
                                  ),
                                if (h.active)
                                  TextButton(
                                    onPressed: s.busy
                                        ? null
                                        : () {
                                            _resetToken();
                                            _cubit.review({
                                              'action': 'redeem',
                                              'holding_id': h.id,
                                            });
                                          },
                                    child: Text(l.investmentRedeem),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: Text(title)),
            body: body,
          );
  }

  Widget _terms(InvestmentRecord p) {
    final l = AppLocalizations.of(context);
    return Text(
      '${l.investmentMinimum}: ${p.text('minimum_amount')} EGP\n'
      '${l.investmentStep}: ${p.text('amount_step')} EGP\n'
      '${l.investmentUnits}: 1 = ${p.text('unit_price')} EGP\n'
      '${l.investmentMaximumPenalty}: ${p.text('max_penalty_percent')}%\n${l.investmentPenaltyFormula}',
    );
  }

  void _resetToken() {
    _token.clear();
    _confirmed = false;
  }

  String _date(String value) =>
      DateTime.tryParse(value)?.toLocal().toString().split('.').first ?? value;
  List<Widget> _review(InvestmentsState s, bool ar) {
    final l = AppLocalizations.of(context), q = s.quote!;
    final redeem = q.text('action') == 'redeem';
    return [
      Text(l.investmentReview, style: Theme.of(context).textTheme.titleLarge),
      Text(q.name(ar)),
      Text('${l.fromAccount}: ${q.text('account_label')}'),
      Text('${l.investmentPrincipal}: ${q.text('principal')} EGP'),
      Text('${l.investmentPenalty}: ${q.text('penalty')} EGP'),
      if (redeem)
        Text('${l.investmentNetCredit}: ${q.text('net_credit')} EGP')
      else
        Text('${l.totalDebit}: ${q.text('principal')} EGP'),
      Text(l.investmentPenaltyFormula),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: s.busy
            ? null
            : () => requestAuthorization(
                context,
                redeem ? 'investment_redeem' : 'investment_subscribe',
                investment: _cubit.draft,
              ),
        child: Text(l.authorizeTitle),
      ),
      const SizedBox(height: 16),
      FaisalTextField(
        controller: _token,
        label: l.authorizationToken,
        obscureText: true,
        onChanged: (_) => setState(() {}),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _confirmed,
        title: Text(l.investmentConfirm),
        onChanged: s.busy
            ? null
            : (v) {
                FocusScope.of(context).unfocus();
                setState(() => _confirmed = v ?? false);
              },
      ),
      FaisalPrimaryButton(
        label: redeem ? l.investmentRedeem : l.investmentSubscribe,
        loading: s.busy,
        onPressed: s.busy || !_confirmed || _token.text.trim().isEmpty
            ? null
            : () => _cubit.submit(_token.text.trim()),
      ),
      TextButton(
        onPressed: s.busy
            ? null
            : () {
                _resetToken();
                _cubit.edit();
              },
        child: Text(l.editTransfer),
      ),
    ];
  }

  List<Widget> _receipt(InvestmentRecord r, bool ar) {
    final l = AppLocalizations.of(context);
    return [
      Icon(
        r.text('status') == 'posted' ? Icons.check_circle : Icons.pending,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      Text(
        r.text('status') == 'posted'
            ? l.investmentCompleted
            : l.investmentPending,
      ),
      SelectableText(r.text('reference')),
      Text(r.name(ar)),
      Text('${l.fromAccount}: ${r.text('account_label')}'),
      Text('${l.amount}: ${r.text('amount')} EGP'),
      Text('${l.investmentPenalty}: ${r.text('penalty')} EGP'),
      Text(_date(r.text('timestamp'))),
      if (r.text('matures_at').isNotEmpty)
        Text('${l.investmentMaturity}: ${_date(r.text('matures_at'))}'),
      TextButton(
        onPressed: () {
          _resetToken();
          _cubit.load();
        },
        child: Text(l.done),
      ),
    ];
  }
}
