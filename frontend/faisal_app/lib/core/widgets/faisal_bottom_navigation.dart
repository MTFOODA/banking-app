import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../routing/app_routes.dart';
import '../theme/faisal_palette.dart';

class FaisalBottomNavigation extends StatelessWidget {
  const FaisalBottomNavigation({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<String> routes = <String>[
    AppRoutes.home,
    AppRoutes.accounts,
    AppRoutes.cards,
    AppRoutes.transfers,
    AppRoutes.more,
  ];

  void _go(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    // `go` (not `push`) keeps a single copy of each primary destination.
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.outline)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _go(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: l10n.accounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card_rounded),
            label: l10n.cards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz_rounded),
            label: l10n.transfers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}
