import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money_input.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/pages/authorization_page.dart';
import '../../domain/entities/transfer_entities.dart';
import '../cubit/transfers_cubit.dart';

class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});
  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  late final _cubit = sl<TransfersCubit>()..load();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _purpose = TextEditingController(),
      _token = TextEditingController();
  final _name = TextEditingController(), _number = TextEditingController();
  final _bank = TextEditingController(),
      _country = TextEditingController(),
      _swift = TextEditingController();
  String? _source, _destination, _beneficiary;
  String _type = 'own_accounts';
  bool _add = false, _confirmed = false;
  bool get _own => _type == 'own_accounts';
  bool get _outbound => !['own_accounts', 'internal'].contains(_type);
  bool get _egpOnly =>
      ['external_domestic', 'wallet', 'instapay'].contains(_type);
  @override
  void dispose() {
    _cubit.close();
    for (final c in [
      _amount,
      _purpose,
      _token,
      _name,
      _number,
      _bank,
      _country,
      _swift,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.transfersTitle)),
      body: SafeArea(
        child: BlocBuilder<TransfersCubit, TransfersState>(
          bloc: _cubit,
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_transferError(l, state.error!)),
                    TextButton(onPressed: _cubit.load, child: Text(l.retry)),
                  ],
                ),
              );
            }
            if (state.result != null) return _receipt(state.result!);
            if (_source != null &&
                !state.accounts.any((a) => a.id == _source)) {
              _source = null;
              _destination = null;
              _beneficiary = null;
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: FaisalSurface(
                    child: state.quote != null
                        ? _review(state)
                        : Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l.transferTypeLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    for (final type in transferTypes)
                                      ChoiceChip(
                                        key: ValueKey('transfer_type_$type'),
                                        label: Text(transferTypeLabel(l, type)),
                                        selected: _type == type,
                                        onSelected: state.submitting
                                            ? null
                                            : (_) => setState(() {
                                                _type = type;
                                                _destination = null;
                                                _beneficiary = null;
                                                _add = false;
                                                _name.clear();
                                                _number.clear();
                                                _bank.clear();
                                                _country.clear();
                                                _swift.clear();
                                                _token.clear();
                                                _confirmed = false;
                                                if (_source != null &&
                                                    _egpOnly &&
                                                    state.accounts
                                                            .firstWhere(
                                                              (a) =>
                                                                  a.id ==
                                                                  _source,
                                                            )
                                                            .currency !=
                                                        'EGP') {
                                                  _source = null;
                                                }
                                              }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_outbound) Text(l.transferSimulationOnly),
                                if (_type == 'international')
                                  Text(l.transferSameCurrency),
                                if (_own) Text(l.ownFxAvailable),
                                if (!_routeAvailable(state))
                                  Text(
                                    l.transferProviderMissing,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                Text(l.transferReviewNote),
                                if (!state.accounts.any(
                                  (a) => !_egpOnly || a.currency == 'EGP',
                                ))
                                  Text(l.transferNoEligibleSource),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'transfer_source_$_type-$_source',
                                  ),
                                  initialValue: _source,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: l.fromAccount,
                                  ),
                                  items: state.accounts
                                      .where(
                                        (a) => !_egpOnly || a.currency == 'EGP',
                                      )
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
                                  onChanged: (v) => setState(() {
                                    _source = v;
                                    _destination = null;
                                    _beneficiary = null;
                                  }),
                                ),
                                if (_source != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      '${l.availableBalance}: ${state.accounts.firstWhere((a) => a.id == _source).availableBalance.toStringAsFixed(2)} ${state.accounts.firstWhere((a) => a.id == _source).currency}',
                                    ),
                                  ),
                                if (_own)
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('destination-$_source'),
                                    initialValue: _destination,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l.toAccount,
                                    ),
                                    items: state.accounts
                                        .where((a) => a.id != _source)
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
                                    onChanged: (v) =>
                                        setState(() => _destination = v),
                                  )
                                else if (_type == 'internal') ...[
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      '$_source-${state.beneficiaries.length}',
                                    ),
                                    initialValue: _beneficiary,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l.savedBeneficiary,
                                    ),
                                    items: state.beneficiaries
                                        .where(
                                          (b) =>
                                              _source == null ||
                                              b.currency ==
                                                  state.accounts
                                                      .firstWhere(
                                                        (a) => a.id == _source,
                                                      )
                                                      .currency,
                                        )
                                        .map(
                                          (b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Text(
                                              '${b.name} • ${b.accountNumberMasked}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    validator: (v) =>
                                        v == null ? l.fieldRequired : null,
                                    onChanged: (v) =>
                                        setState(() => _beneficiary = v),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _add = !_add),
                                    child: Text(l.newBeneficiary),
                                  ),
                                  if (_add) ...[
                                    Text(l.internalTransferOnly),
                                    FaisalTextField(
                                      controller: _name,
                                      label: l.beneficiaryName,
                                    ),
                                    FaisalTextField(
                                      controller: _number,
                                      label: l.accountNumber,
                                      keyboardType: TextInputType.number,
                                    ),
                                    TextButton(
                                      onPressed: state.submitting
                                          ? null
                                          : () async {
                                              if (_name.text.trim().length <
                                                      2 ||
                                                  _number.text.trim().length <
                                                      6) {
                                                return;
                                              }
                                              final saved = await _cubit
                                                  .addBeneficiary(
                                                    name: _name.text.trim(),
                                                    bankName: 'Fictional Internal Bank',
                                                    accountNumber: _number.text,
                                                    currency: _source == null
                                                        ? 'EGP'
                                                        : state.accounts
                                                              .firstWhere(
                                                                (a) =>
                                                                    a.id ==
                                                                    _source,
                                                              )
                                                              .currency,
                                                  );
                                              if (mounted && saved) {
                                                setState(() {
                                                  _add = false;
                                                  _beneficiary = _cubit
                                                      .state
                                                      .beneficiaries
                                                      .last
                                                      .id;
                                                });
                                              }
                                            },
                                      child: Text(l.addBeneficiary),
                                    ),
                                  ],
                                ] else
                                  ..._outboundFields(l),
                                const SizedBox(height: 20),
                                FaisalTextField(
                                  key: const ValueKey('transfer_amount'),
                                  controller: _amount,
                                  label: l.amount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
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
                                    if (_source != null &&
                                        amount >
                                            state.accounts
                                                .firstWhere(
                                                  (a) => a.id == _source,
                                                )
                                                .availableBalance) {
                                      return l.insufficientFunds;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                FaisalTextField(
                                  key: const ValueKey('transfer_purpose'),
                                  controller: _purpose,
                                  label: l.purpose,
                                  maxLength: 160,
                                  validator: (v) => (v ?? '').trim().isEmpty
                                      ? l.fieldRequired
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                FaisalPrimaryButton(
                                  key: const ValueKey('transfer_review'),
                                  label: l.reviewTransfer,
                                  loading: state.submitting,
                                  onPressed: !_routeAvailable(state)
                                      ? null
                                      : () {
                                          if (!_routeAvailable(state)) return;
                                          if (!_form.currentState!.validate()) {
                                            return;
                                          }
                                          final source = state.accounts
                                              .firstWhere(
                                                (a) => a.id == _source,
                                              );
                                          _cubit.review({
                                            'transfer_type': _type,
                                            'source_account_id': _source,
                                            'currency': source.currency,
                                            'amount': normalizeMoney(
                                              _amount.text,
                                            ),
                                            'destination_account_id': _own
                                                ? _destination
                                                : null,
                                            'beneficiary_id':
                                                _type == 'internal'
                                                ? _beneficiary
                                                : null,
                                            if (_outbound)
                                              'recipient': {
                                                'name': _name.text.trim(),
                                                'destination': _number.text
                                                    .trim(),
                                                if ([
                                                  'external_domestic',
                                                  'international',
                                                ].contains(_type))
                                                  'bank_name': _bank.text
                                                      .trim(),
                                                if (_type ==
                                                    'international') ...{
                                                  'country_code': _country.text
                                                      .trim()
                                                      .toUpperCase(),
                                                  'swift_code': _swift.text
                                                      .trim()
                                                      .toUpperCase(),
                                                },
                                              },
                                            'purpose': _purpose.text.trim(),
                                          });
                                        },
                                ),
                                if (state.submitError != null)
                                  Text(_transferError(l, state.submitError!)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _review(TransfersState state) {
    final l = AppLocalizations.of(context), q = state.quote!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.reviewTransfer, style: Theme.of(context).textTheme.titleLarge),
        Text(
          transferTypeLabel(
            l,
            state.draft!['transfer_type'] as String? ?? 'own_accounts',
          ),
        ),
        if (_outbound) Text(l.transferSimulationOnly),
        Text('${l.fromAccount}: ${q['source_label']}'),
        Text('${l.toAccount}: ${q['destination_label']}'),
        Text('${l.beneficiaryName}: ${q['beneficiary']}'),
        if (q['bank_name'] != null)
          Text('${l.transferBankName}: ${q['bank_name']}'),
        if (q['country_code'] != null)
          Text('${l.transferCountry}: ${q['country_code']}'),
        if (q['swift_code'] != null)
          Text('${l.transferSwift}: ${q['swift_code']}'),
        Text('${l.amount}: ${q['amount']} ${q['currency']}'),
        Text('${l.fees}: ${q['fees']} ${q['currency']}'),
        Text('${l.totalDebit}: ${q['total_debit']} ${q['currency']}'),
        if (q['exchange_rate'] != null) ...[
          _exchangeRate(
            l.ownFxRate,
            '${q['currency']}',
            q['exchange_rate'],
            '${q['received_currency']}',
          ),
          Text(
            '${l.ownFxReceived}: ${q['received_amount']} ${q['received_currency']}',
          ),
          Text('${l.ownFxAsOf}: ${_dateText(q['rate_as_of'])}'),
          Text('${l.ownFxExpires}: ${_dateText(q['fx_quote_expires_at'])}'),
          Text(l.ownFxSimulation),
        ],
        Text('${l.purpose}: ${state.draft!['purpose']}'),
        Text(l.transferReviewNote),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: state.submitting
              ? null
              : () => requestAuthorization(
                  context,
                  'transfer',
                  transfer: state.draft,
                ),
          child: Text(l.authorizeTitle),
        ),
        const SizedBox(height: 16),
        FaisalTextField(
          key: const ValueKey('transfer_token'),
          controller: _token,
          label: l.authorizationToken,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _confirmed,
          title: Text(l.transferExplicitConfirmation),
          onChanged: (v) {
            FocusScope.of(context).unfocus();
            setState(() => _confirmed = v ?? false);
          },
        ),
        FaisalPrimaryButton(
          key: const ValueKey('transfer_confirm'),
          label: l.confirmTransfer,
          loading: state.submitting,
          onPressed: !_confirmed || _token.text.trim().isEmpty
              ? null
              : () => _cubit.submitReviewed(_token.text.trim()),
        ),
        TextButton(
          onPressed: state.submitting
              ? null
              : () {
                  _token.clear();
                  _confirmed = false;
                  _cubit.resetSubmission();
                },
          child: Text(l.editTransfer),
        ),
        if (state.submitError != null)
          Text(_transferError(l, state.submitError!)),
      ],
    );
  }

  Widget _receipt(TransferResult result) {
    final l = AppLocalizations.of(context);
    final success =
        result.status == 'posted' || result.status == 'simulated_completed';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FaisalSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.pending_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  result.status == 'simulated_completed'
                      ? l.transferSimulationSuccess
                      : (success ? l.transferSuccess : l.transferReceipt),
                ),
                if (result.transferType != null)
                  Text(transferTypeLabel(l, result.transferType!)),
                Text(result.reference),
                Text('${result.amount.toStringAsFixed(2)} ${result.currency}'),
                Text(result.destinationLabel),
                Text(
                  '${l.fees}: ${result.fees.toStringAsFixed(2)} ${result.currency}',
                ),
                Text(
                  '${l.totalDebit}: ${(result.totalDebit ?? result.amount + result.fees).toStringAsFixed(2)} ${result.currency}',
                ),
                Text(
                  FaisalFormatters.dateTime(
                    result.createdAt.toLocal(),
                    locale: Localizations.localeOf(context).languageCode,
                  ),
                ),
                if (result.status != 'simulated_completed')
                  Text(transactionStatusLabel(l, result.status)),
                if (result.recipientName != null) Text(result.recipientName!),
                if (result.purpose != null)
                  Text('${l.purpose}: ${result.purpose}'),
                if (result.exchangeRate != null) ...[
                  _exchangeRate(
                    l.ownFxRate,
                    result.currency,
                    result.exchangeRate,
                    result.receivedCurrency!,
                  ),
                  Text(
                    '${l.ownFxReceived}: ${result.receivedAmount?.toStringAsFixed(2)} ${result.receivedCurrency}',
                  ),
                  Text('${l.ownFxAsOf}: ${_dateText(result.rateAsOf)}'),
                  Text(l.ownFxSimulation),
                ],
                if (result.bankName != null) Text(result.bankName!),
                if (result.countryCode != null)
                  Text('${l.transferCountry}: ${result.countryCode}'),
                if (result.providerReference != null)
                  SelectableText(
                    '${l.transferProviderReference}: ${result.providerReference}',
                  ),
                if (result.status == 'simulated_completed')
                  Text(l.transferSimulationOnly),
                Text(l.transferReviewNote),
                TextButton(
                  onPressed: () {
                    _token.clear();
                    _confirmed = false;
                    _cubit.resetSubmission();
                    _cubit.load();
                  },
                  child: Text(l.done),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _routeAvailable(TransfersState state) => state.options.any(
    (o) => o['transfer_type'] == _type && o['available'] == true,
  );
  String _transferError(AppLocalizations l, AppException error) =>
      serverErrorCode(error) == 'validation_error'
      ? l.transferDestinationInvalid
      : securityError(l, error);
  Widget _exchangeRate(
    String label,
    String source,
    Object? rate,
    String destination,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$label:'),
      Text(
        '1 $source = ${_rateText(rate)} $destination',
        textDirection: TextDirection.ltr,
        textAlign: Directionality.of(context) == TextDirection.rtl
            ? TextAlign.end
            : TextAlign.start,
      ),
    ],
  );
  String _rateText(Object? value) => '$value'.contains('.')
      ? '$value'
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '')
      : '$value';
  String _dateText(Object? value) {
    final date = DateTime.tryParse('$value');
    return date == null
        ? ''
        : FaisalFormatters.dateTime(
            date.toLocal(),
            locale: Localizations.localeOf(context).languageCode,
          );
  }

  List<Widget> _outboundFields(AppLocalizations l) => [
    const SizedBox(height: 16),
    FaisalTextField(
      key: const ValueKey('transfer_recipient_name'),
      controller: _name,
      label: l.beneficiaryName,
      maxLength: 120,
      validator: (v) => (v ?? '').trim().length < 2 ? l.fieldRequired : null,
    ),
    const SizedBox(height: 12),
    FaisalTextField(
      key: const ValueKey('transfer_recipient_destination'),
      controller: _number,
      label: _type == 'wallet'
          ? l.transferWalletNumber
          : (_type == 'instapay' ? l.transferIpa : l.transferAccountOrIban),
      keyboardType: _type == 'wallet'
          ? TextInputType.phone
          : TextInputType.text,
      maxLength: 128,
      validator: (v) =>
          (v ?? '').trim().length < 3 ? l.transferDestinationInvalid : null,
    ),
    if (_type == 'instapay') Text(l.transferIpaHint),
    if (['external_domestic', 'international'].contains(_type)) ...[
      const SizedBox(height: 12),
      FaisalTextField(
        key: const ValueKey('transfer_recipient_bank'),
        controller: _bank,
        label: l.transferBankName,
        maxLength: 120,
        validator: (v) => (v ?? '').trim().length < 2 ? l.fieldRequired : null,
      ),
    ],
    if (_type == 'international') ...[
      const SizedBox(height: 12),
      FaisalTextField(
        key: const ValueKey('transfer_recipient_country'),
        controller: _country,
        label: l.transferCountry,
        maxLength: 2,
        validator: (v) => RegExp(r'^[A-Za-z]{2}$').hasMatch((v ?? '').trim())
            ? null
            : l.transferDestinationInvalid,
      ),
      const SizedBox(height: 12),
      FaisalTextField(
        key: const ValueKey('transfer_recipient_swift'),
        controller: _swift,
        label: l.transferSwift,
        maxLength: 11,
        validator: (v) => [8, 11].contains((v ?? '').trim().length)
            ? null
            : l.transferDestinationInvalid,
      ),
    ],
  ];
}

const transferTypes = [
  'own_accounts',
  'internal',
  'external_domestic',
  'international',
  'wallet',
  'instapay',
];
String transferTypeLabel(AppLocalizations l, String type) => switch (type) {
  'own_accounts' => l.transferOwnType,
  'internal' => l.transferInternalType,
  'external_domestic' => l.transferDomesticType,
  'international' => l.transferInternationalType,
  'wallet' => l.transferWalletType,
  'instapay' => l.transferInstapayType,
  _ => l.transfersTitle,
};
