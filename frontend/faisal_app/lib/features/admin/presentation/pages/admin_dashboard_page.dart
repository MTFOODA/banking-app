import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/admin_dashboard_cubit.dart';
import 'admin_frame.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';

/// Staff landing page backed exclusively by permission-protected admin APIs.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final _cubit = AdminDashboardCubit(sl<AdminRepository>())..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AdminFrame(
      title: l.dashboard,
      index: 0,
      onRefresh: _cubit.load,
      child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(securityError(l, state.error!)),
                  FilledButton(onPressed: _cubit.load, child: Text(l.retry)),
                ],
              ),
            );
          }
          final data = state.dashboard!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l.dashboard,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              for (final item in [
                (l.customers, data.customersCount),
                (l.activeAccounts, data.activeAccounts),
                (l.pendingRequests, data.pendingRequests),
                (l.publishedAnnouncements, data.publishedAnnouncements),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FaisalSurface(
                    child: ListTile(
                      title: Text(item.$1),
                      trailing: Text(
                        '${item.$2}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.adminRequests),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(l.requestQueue),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.adminAnnouncements),
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(l.announcementsAdmin),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.adminSettings),
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l.settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l.recentActions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final entry in state.auditEntries)
                ListTile(
                  title: Text(entry.action),
                  subtitle: Text(
                    entry.createdAt.toLocal().toString().split('.').first,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
