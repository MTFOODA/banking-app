import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/bank_definition.dart';
import 'bank_catalogue_cubit.dart';

class BankSelector extends StatelessWidget {
  const BankSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.registrationOnly = false,
    this.enabled = true,
    this.requiredSelection = true,
    this.label,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool registrationOnly, enabled;
  final bool requiredSelection;
  final String? label;
  @override
  Widget build(BuildContext context) {
    Widget field(BankCatalogue catalogue) {
      final l = AppLocalizations.of(context),
          language = Localizations.localeOf(context).languageCode;
      final banks = catalogue.banks
          .where((b) => !registrationOnly || b.registrationEnabled)
          .toList();
      final selected = banks.any((b) => b.code == value) ? value : null;
      return DropdownButtonFormField<String>(
        key: ValueKey('bank-selector-$selected-${catalogue.version}'),
        initialValue: selected,
        isExpanded: true,
        menuMaxHeight: 380,
        itemHeight: 64,
        decoration: InputDecoration(labelText: label ?? l.bankSelectionLabel),
        items: [
          if (!requiredSelection)
            DropdownMenuItem<String>(
              value: null,
              child: Text(l.bankLoginAutomatic),
            ),
          ...banks.map(
            (bank) => DropdownMenuItem(
              value: bank.code,
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 20,
                    color: Color(
                      0xff000000 |
                          int.parse(bank.primary.substring(1), radix: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bank.name(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        validator: (v) =>
            requiredSelection && v == null ? l.bankSelectionRequired : null,
        onChanged: enabled ? onChanged : null,
      );
    }

    if (!sl.isRegistered<BankCatalogueCubit>()) {
      return field(BankCatalogue.bundled);
    }
    return BlocBuilder<BankCatalogueCubit, BankCatalogue>(
      bloc: sl<BankCatalogueCubit>(),
      builder: (_, catalogue) => field(catalogue),
    );
  }
}
