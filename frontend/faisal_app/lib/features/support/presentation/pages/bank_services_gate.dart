import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../banks/presentation/bank_catalogue_cubit.dart';
import '../../../banks/presentation/bank_selector.dart';
import '../services/bank_contact_links.dart';
import 'branch_directory_page.dart';
import 'public_bank_services_page.dart';

enum BankServiceKind { branches, atms, callCenter }

/// Never labels Faisal's bundled locations/hotline as another bank's data.
class BankServicesGate extends StatefulWidget {
  const BankServicesGate({super.key, required this.kind});
  final BankServiceKind kind;
  @override
  State<BankServicesGate> createState() => _BankServicesGateState();
}

class _BankServicesGateState extends State<BankServicesGate> {
  String? bankCode;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      try {
        bankCode = context.read<AuthBloc>().state.user?.profile?.bankCode;
      } catch (_) {}
    }
  }

  Widget original([String? bankName]) => switch (widget.kind) {
    BankServiceKind.branches => BranchDirectoryPage(bankName: bankName),
    BankServiceKind.atms => AtmLocatorPage(bankName: bankName),
    BankServiceKind.callCenter => CallCenterPage(bankName: bankName),
  };
  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<BankCatalogueCubit>()) {
      return original();
    }
    final l = AppLocalizations.of(context),
        catalogue = sl<BankCatalogueCubit>().state;
    final bank = catalogue.find(bankCode);
    final title = switch (widget.kind) {
      BankServiceKind.branches => l.publicBranches,
      BankServiceKind.atms => l.publicAtms,
      BankServiceKind.callCenter => l.publicCallCenter,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.bankServiceChoose),
                const SizedBox(height: 16),
                BankSelector(
                  value: bankCode,
                  onChanged: (value) => setState(() => bankCode = value),
                ),
                const SizedBox(height: 20),
                if (bank != null) ...[
                  Text(
                    bank.name(Localizations.localeOf(context).languageCode),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(l.bankDirectoryNote),
                  const SizedBox(height: 20),
                  if (bank.code == 'faisal')
                    FilledButton.icon(
                      key: const Key('bank-open-directory'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => original(
                            bank.name(
                              Localizations.localeOf(context).languageCode,
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(title),
                    )
                  else
                    FilledButton.icon(
                      key: const Key('bank-official-service'),
                      onPressed: () => openBankLink(
                        context,
                        sl<BankContactLinks>(),
                        Uri.parse(bank.website),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l.bankOfficialWebsite),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
