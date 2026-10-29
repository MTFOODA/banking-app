import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/faisal_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../authentication/presentation/pages/login_widgets.dart';
import '../../settings/presentation/cubit/appearance_cubits.dart';
import '../domain/entities/bank_definition.dart';
import 'bank_catalogue_cubit.dart';
import 'bank_logo.dart';
import 'bank_selection_cubit.dart';

class BankOnboardingPage extends StatefulWidget {
  const BankOnboardingPage({super.key});
  @override
  State<BankOnboardingPage> createState() => _BankOnboardingPageState();
}

class _BankOnboardingPageState extends State<BankOnboardingPage> {
  late final selection = sl<BankSelectionCubit>();
  late final controller = PageController(
    initialPage: selection.introductionSeen ? 2 : 0,
  );
  late int page = selection.introductionSeen ? 2 : 0;
  String query = '';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.appName),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FaisalLanguageToggle(
              languageCode: language,
              onChanged: context.read<LanguageCubit>().change,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (v) => setState(() => page = v),
                children: [
                  _intro(
                    l.bankIntroTitle,
                    l.bankIntroBody,
                    Icons.account_balance_wallet_outlined,
                  ),
                  _intro(
                    l.bankSecurityIntroTitle,
                    l.bankSecurityIntroBody,
                    Icons.verified_user_outlined,
                  ),
                  BlocBuilder<BankCatalogueCubit, BankCatalogue>(
                    bloc: sl<BankCatalogueCubit>(),
                    builder: (context, catalogue) {
                      final banks = catalogue.banks
                          .where(
                            (b) =>
                                b.registrationEnabled &&
                                ('${b.nameAr} ${b.nameEn} ${b.abbreviation}'
                                    .toLowerCase()
                                    .contains(query.toLowerCase())),
                          )
                          .toList();
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l.bankChooseTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(l.bankChooseBody),
                                    const SizedBox(height: 16),
                                    TextField(
                                      key: const Key('bank-onboarding-search'),
                                      decoration: InputDecoration(
                                        labelText: l.bankSearchLabel,
                                        prefixIcon: const Icon(Icons.search),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => query = v),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, box) => GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      20,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: box.maxWidth >= 750
                                              ? 3
                                              : 2,
                                          mainAxisExtent: 170,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemCount: banks.length,
                                    itemBuilder: (context, index) {
                                      final bank = banks[index];
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          key: ValueKey(
                                            'choose-bank-${bank.code}',
                                          ),
                                          onTap: () async {
                                            await selection.select(bank.code);
                                            if (context.mounted) {
                                              context.go(AppRoutes.login);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                BankLogo(bank: bank, size: 64),
                                                const SizedBox(height: 12),
                                                Text(
                                                  bank.name(language),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: page == i
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (page < 2)
                    FilledButton(
                      key: const Key('bank-onboarding-next'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                      onPressed: () => controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(l.continueLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(String title, String body, IconData icon) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaisalLogo(size: 64),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                icon,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
