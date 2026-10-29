import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/bank_directory_repository.dart';
import '../cubit/branch_directory_cubit.dart';
import '../services/bank_contact_links.dart';

class BranchDirectoryPage extends StatefulWidget {
  const BranchDirectoryPage({
    super.key,
    this.bankName,
    this.bankCode = 'faisal',
    this.atms = false,
  });
  final String? bankName;
  final String bankCode;
  final bool atms;
  @override
  State<BranchDirectoryPage> createState() => _BranchDirectoryPageState();
}

class _BranchDirectoryPageState extends State<BranchDirectoryPage> {
  late final cubit = BranchDirectoryCubit(
    sl<BankDirectoryRepository>(),
    bankCode: widget.bankCode,
    atms: widget.atms,
  )..load();
  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = widget.atms ? l.publicAtms : l.publicBranches;
    return Scaffold(
      backgroundColor: context.palette.softSurface,
      appBar: AppBar(
        title: Text(
          widget.bankName == null ? title : '$title · ${widget.bankName}',
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: FaisalLogo(size: 32),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocBuilder<BranchDirectoryCubit, BranchDirectoryState>(
            bloc: cubit,
            builder: (context, s) {
              final rows = s.visible;
              final status = widget.atms
                  ? s.directory?.atmsStatus
                  : s.directory?.branchesStatus;
              final locator = widget.atms
                  ? s.directory?.atmLocatorUrl
                  : s.directory?.branchLocatorUrl;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        TextField(
                          key: const ValueKey('branch_search'),
                          onChanged: (v) => cubit.filter(query: v),
                          decoration: InputDecoration(
                            labelText: widget.atms
                                ? l.publicAtmArea
                                : l.publicBranchSearch,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('branch_governorate'),
                          initialValue: s.governorate ?? '',
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.publicGovernorate,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(l.publicAllGovernorates),
                            ),
                            for (final g in s.governorates)
                              DropdownMenuItem(value: g, child: Text(g)),
                          ],
                          onChanged: (v) => cubit.filter(
                            governorate: v,
                            clearGovernorate: v == '',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  Expanded(
                    child: s.loading
                        ? const Center(child: CircularProgressIndicator())
                        : s.error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.publicDirectoryFailed),
                                TextButton(
                                  onPressed: cubit.load,
                                  child: Text(l.retry),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: cubit.load,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: rows.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '${l.publicResultCount}: ${rows.length}',
                                        key: const ValueKey('branch_count'),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l.publicMapSearchNote,
                                        style: context.texts.bodySmall,
                                      ),
                                      if (s.directory?.reviewedAt != null)
                                        Text(
                                          '${l.bankDirectoryReviewed}: ${s.directory!.reviewedAt}',
                                          style: context.texts.bodySmall,
                                        ),
                                      if (status == 'unavailable' ||
                                          status == 'partial' ||
                                          status == 'not_applicable')
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            status == 'partial'
                                                ? l.bankDirectoryPartial
                                                : l.bankDirectoryUnavailable,
                                          ),
                                        ),
                                      if (locator != null)
                                        TextButton.icon(
                                          key: const Key(
                                            'bank-official-locator',
                                          ),
                                          onPressed: () => openBankLink(
                                            context,
                                            sl<BankContactLinks>(),
                                            locator,
                                          ),
                                          icon: const Icon(Icons.open_in_new),
                                          label: Text(l.publicOfficialLocator),
                                        ),
                                      const SizedBox(height: 16),
                                      if (rows.isEmpty &&
                                          status != 'unavailable')
                                        Text(l.publicDirectoryEmpty),
                                    ],
                                  );
                                }
                                final branch = rows[index - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: FaisalSurface(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              widget.atms
                                                  ? Icons.local_atm_outlined
                                                  : Icons
                                                        .account_balance_outlined,
                                              color: context.colors.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                branch.name,
                                                style:
                                                    context.texts.titleMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (branch.governorate.isNotEmpty)
                                          Text(
                                            branch.governorate,
                                            style: context.texts.labelLarge,
                                          ),
                                        const SizedBox(height: 6),
                                        SelectableText(branch.address),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          key: ValueKey(
                                            'branch_map_${branch.id}',
                                          ),
                                          onPressed: () => openBankLink(
                                            context,
                                            sl<BankContactLinks>(),
                                            branch.mapsUri,
                                          ),
                                          icon: const Icon(Icons.map_outlined),
                                          label: Text(l.publicOpenMap),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
