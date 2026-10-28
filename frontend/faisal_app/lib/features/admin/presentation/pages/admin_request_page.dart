import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/labels.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/admin_request_detail_cubit.dart';
import 'admin_frame.dart';

class AdminRequestDetailsPage extends StatefulWidget {
  const AdminRequestDetailsPage({super.key, required this.id});
  final String id;
  @override
  State<AdminRequestDetailsPage> createState() =>
      _AdminRequestDetailsPageState();
}

class _AdminRequestDetailsPageState extends State<AdminRequestDetailsPage> {
  late final _cubit = AdminRequestDetailCubit(sl<AdminRepository>(), widget.id)
    ..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _decide(bool approve) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AdminDecisionDialog(approve: approve),
    );
    if (reason == null || !mounted) return;
    final ok = await _cubit.decide(
      approve: approve,
      reason: reason,
      explanation: reason.isEmpty ? null : reason,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).admDecisionSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AdminFrame(
      title: l.admDetails,
      back: true,
      onRefresh: _cubit.load,
      child: BlocBuilder<AdminRequestDetailCubit, AdminRequestDetailState>(
        bloc: _cubit,
        builder: (context, s) {
          if (s.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(securityError(l, s.error!)),
                  TextButton(onPressed: _cubit.load, child: Text(l.retry)),
                ],
              ),
            );
          }
          final r = s.detail!.request;
          final canDecide =
              context.read<AuthBloc>().state.can('admin.requests.decide') &&
              [
                'submitted',
                'under_review',
                'pending_approval',
                'pending_customer_info',
              ].contains(r.status);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FaisalSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      r.reference,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(requestTypeLabel(l, r.requestType)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FaisalStatusBadge(
                        label: requestStatusLabel(l, r.status),
                        tone: FaisalStatusBadge.toneForStatus(r.status),
                      ),
                    ),
                    const Divider(),
                    Text(
                      '${l.admCustomer}: ${(Localizations.localeOf(context).languageCode == 'ar' ? s.detail!.customer?.nameAr : s.detail!.customer?.nameEn) ?? ''}',
                    ),
                    for (final entry in r.formData.entries.where(
                      (entry) =>
                          r.requestType != 'card_issue' ||
                          {
                            'account_number_masked',
                            'currency',
                            'account_type',
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'product_name_ar'
                                : 'product_name_en',
                          }.contains(entry.key),
                    ))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${_fieldLabel(l, entry.key)}: ${entry.value}',
                        ),
                      ),
                    if (r.decisionReason != null) ...[
                      const Divider(),
                      Text('${l.decisionReason}: ${r.decisionReason}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (s.actionError != null) Text(securityError(l, s.actionError!)),
              if (s.busy)
                const Center(child: CircularProgressIndicator())
              else if (canDecide)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('admin_approve'),
                      onPressed: () => _decide(true),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l.approve),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('admin_reject'),
                      onPressed: () => _decide(false),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(l.reject),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                l.admHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final entry in r.history)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(requestStatusLabel(l, entry.toStatus)),
                  subtitle: Text(
                    '${entry.note ?? ''}\n${entry.createdAt.toLocal().toString().split('.').first}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _fieldLabel(AppLocalizations l, String key) => switch (key) {
  'email' => l.admDataEmail,
  'phone' => l.admDataPhone,
  'address' => l.admDataAddress,
  'product_code' => l.admDataProduct,
  'card_product_code' ||
  'product_name_en' ||
  'product_name_ar' => l.cardProductLabel,
  'account_number_masked' || 'account_type' => l.admDataAccount,
  'issued_card_id' => l.admDataCard,
  'account_id' => l.admDataAccount,
  'currency' => l.admDataCurrency,
  'card_id' => l.admDataCard,
  'amount' || 'requested_amount' => l.admDataAmount,
  'reason' => l.admDataReason,
  'message' => l.message,
  _ => key.replaceAll('_', ' '),
};

class AdminDecisionDialog extends StatefulWidget {
  const AdminDecisionDialog({super.key, required this.approve});
  final bool approve;
  @override
  State<AdminDecisionDialog> createState() => _AdminDecisionDialogState();
}

class _AdminDecisionDialogState extends State<AdminDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _submitted = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.approve ? l.confirmApprove : l.confirmReject),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const ValueKey('admin_decision_reason'),
          controller: _reason,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            errorMaxLines: 3,
            labelText: widget.approve
                ? l.customerExplanation
                : l.decisionReason,
          ),
          validator: (v) => !widget.approve && (v ?? '').trim().length < 5
              ? l.rejectionReasonRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('admin_decision_confirm'),
          onPressed: _submitted
              ? null
              : () {
                  if (_form.currentState!.validate()) {
                    setState(() => _submitted = true);
                    Navigator.pop(context, _reason.text.trim());
                  }
                },
          child: Text(widget.approve ? l.approve : l.reject),
        ),
      ],
    );
  }
}
