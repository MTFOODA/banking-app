import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_loading_view.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../core/widgets/faisal_transaction_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../cubit/transactions_cubit.dart';
import 'transaction_details_sheet.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({
    super.key,
    this.scope = TransactionScope.all,
    this.scopeId,
    this.title,
  });

  final TransactionScope scope;
  final String? scopeId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TransactionsCubit>(param1: scope, param2: scopeId)..load(),
      child: _TransactionsView(pageTitle: title),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView({this.pageTitle});

  final String? pageTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: FaisalAppBar(
            title: pageTitle ?? l10n.transactionsTitle,
            actions: [
              IconButton(
                tooltip: l10n.refresh,
                onPressed: () => context.read<TransactionsCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) =>
                      context.read<TransactionsCubit>().applyFilter(
                        state.filter.copyWith(
                          search: value,
                          clearSearch: value.isEmpty,
                        ),
                      ),
                ),
              ),
              Expanded(child: _buildList(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, TransactionsState state) {
    final l10n = AppLocalizations.of(context);
    if (state.loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: FaisalListSkeleton(rows: 7),
      );
    }
    if (state.error != null) {
      return FaisalErrorView(
        error: state.error!,
        onRetry: () => context.read<TransactionsCubit>().load(),
      );
    }
    if (state.items.isEmpty) {
      return FaisalEmptyState(
        title: l10n.noTransactionsFound,
        icon: Icons.receipt_long_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.xxl,
      ),
      itemCount: state.items.length + (state.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FaisalSecondaryButton(
              label: l10n.loadingMore,
              loading: state.loadingMore,
              onPressed: () => context.read<TransactionsCubit>().loadMore(),
            ),
          );
        }
        final transaction = state.items[index];
        return FaisalTransactionTile(
          transaction: transaction,
          showAccount: true,
          onTap: () => showTransactionDetails(context, transaction),
        );
      },
    );
  }
}
