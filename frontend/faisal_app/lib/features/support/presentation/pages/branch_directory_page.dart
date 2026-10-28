import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/bank_directory_repository.dart';
import '../cubit/branch_directory_cubit.dart';
import '../services/bank_contact_links.dart';

class BranchDirectoryPage extends StatefulWidget {
  const BranchDirectoryPage({super.key, this.bankName});
  final String? bankName;
  @override
  State<BranchDirectoryPage> createState() => _BranchDirectoryPageState();
}

class _BranchDirectoryPageState extends State<BranchDirectoryPage> {
  late final _cubit = BranchDirectoryCubit(sl<BankDirectoryRepository>())
    ..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.softSurface,
      appBar: AppBar(
        title: Text(
          widget.bankName == null
              ? l.publicBranches
              : '${l.publicBranches} · ${widget.bankName}',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocBuilder<BranchDirectoryCubit, BranchDirectoryState>(
            bloc: _cubit,
            builder: (context, s) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      TextField(
                        key: const ValueKey('branch_search'),
                        onChanged: (v) => _cubit.filter(query: v),
                        decoration: InputDecoration(
                          labelText: l.publicBranchSearch,
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
                        onChanged: (v) => _cubit.filter(
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
                                onPressed: _cubit.load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            Text(
                              '${l.publicResultCount}: ${s.visible.length}',
                              key: const ValueKey('branch_count'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.publicMapSearchNote,
                              style: context.texts.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            if (s.visible.isEmpty) Text(l.publicDirectoryEmpty),
                            for (final branch in s.visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FaisalSurface(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.account_balance_outlined,
                                            color: context.colors.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              branch.name,
                                              style: context.texts.titleMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
