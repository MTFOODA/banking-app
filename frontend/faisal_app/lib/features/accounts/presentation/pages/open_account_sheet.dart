import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_entities.dart';
import '../cubit/accounts_cubit.dart';

/// Bottom sheet for opening a new account. The request is submitted to the API
/// and the resulting reference is displayed; balances change only after staff
/// approval.
Future<void> showOpenAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) => sl<AccountRequestCubit>()..loadProducts(),
      child: const _OpenAccountSheet(),
    ),
  );
}

class _OpenAccountSheet extends StatefulWidget {
  const _OpenAccountSheet();

  @override
  State<_OpenAccountSheet> createState() => _OpenAccountSheetState();
}

class _OpenAccountSheetState extends State<_OpenAccountSheet> {
  AccountProduct? _selected;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: BlocConsumer<AccountRequestCubit, AccountRequestState>(
        listener: (context, state) {
          if (state is AccountRequestSubmitted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.requestSubmittedMessage(state.reference)),
              ),
            );
          }
        },
        builder: (context, state) {
          final products = state is AccountRequestProductsLoaded
              ? state.products
              : const <AccountProduct>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.openAccount, style: context.texts.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.selectProduct,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state is AccountRequestFailure)
                Text(
                  l10n.errorUnexpected,
                  style: TextStyle(color: context.palette.danger),
                ),
              if (products.isNotEmpty)
                RadioGroup<AccountProduct>(
                  groupValue: _selected,
                  onChanged: (value) => setState(() => _selected = value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...products.map(
                        (product) => RadioListTile<AccountProduct>(
                          value: product,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            locale == 'ar' ? product.nameAr : product.nameEn,
                            style: context.texts.titleSmall,
                          ),
                          subtitle: Text(
                            '${l10n.minimumBalance}: ${FaisalFormatters.money(product.minimumBalance, currency: product.currency, locale: locale)}',
                            style: context.texts.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.note,
                  hintText: l10n.optional,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FaisalPrimaryButton(
                label: l10n.submit,
                loading: state is AccountRequestSubmitting,
                onPressed:
                    _selected == null || state is AccountRequestSubmitting
                    ? null
                    : () => context.read<AccountRequestCubit>().submitOpen(
                        productCode: _selected!.code,
                        reason: _reasonController.text.trim(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
