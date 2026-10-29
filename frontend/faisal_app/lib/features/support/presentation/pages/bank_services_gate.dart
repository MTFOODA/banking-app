import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../banks/presentation/bank_catalogue_cubit.dart';
import '../../../banks/presentation/bank_selection_cubit.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import 'branch_directory_page.dart';
import 'public_bank_services_page.dart';

enum BankServiceKind { branches, atms, callCenter }

/// Bank services follow the server profile while signed in, or the global
/// pre-login selection. A local choice never changes account ownership.
class BankServicesGate extends StatelessWidget {
  const BankServicesGate({super.key, required this.kind});
  final BankServiceKind kind;
  @override
  Widget build(BuildContext context) {
    String? code;
    try {
      code = context.watch<AuthBloc>().state.user?.profile?.bankCode;
    } catch (_) {}
    code ??= sl.isRegistered<BankSelectionCubit>()
        ? sl<BankSelectionCubit>().state
        : 'faisal';
    final catalogue = sl.isRegistered<BankCatalogueCubit>()
        ? sl<BankCatalogueCubit>().state
        : BankCatalogue.bundled;
    final bank = catalogue.find(code);
    if (bank == null) return const SizedBox.shrink();
    final name = bank.name(Localizations.localeOf(context).languageCode);
    return switch (kind) {
      BankServiceKind.branches => BranchDirectoryPage(
        key: ValueKey('${bank.code}-branches'),
        bankCode: bank.code,
        bankName: name,
      ),
      BankServiceKind.atms => BranchDirectoryPage(
        key: ValueKey('${bank.code}-atms'),
        bankCode: bank.code,
        bankName: name,
        atms: true,
      ),
      BankServiceKind.callCenter => CallCenterPage(
        key: ValueKey('${bank.code}-contact'),
        bankCode: bank.code,
        bankName: name,
      ),
    };
  }
}
