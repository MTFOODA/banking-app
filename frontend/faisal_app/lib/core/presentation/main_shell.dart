import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/faisal_bottom_navigation.dart';

/// Shell for the five primary customer tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexFor(String location) {
    if (location.startsWith('/accounts')) {
      return 1;
    }
    if (location.startsWith('/cards')) {
      return 2;
    }
    if (location.startsWith('/transfers')) {
      return 3;
    }
    if (location.startsWith('/more') ||
        location.startsWith('/requests') ||
        location.startsWith('/settings') ||
        location.startsWith('/profile') ||
        location.startsWith('/support') ||
        location.startsWith('/products') ||
        location.startsWith('/notifications') ||
        location.startsWith('/payments') ||
        location.startsWith('/repayments')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: FaisalBottomNavigation(
        currentIndex: _indexFor(location),
      ),
    );
  }
}
