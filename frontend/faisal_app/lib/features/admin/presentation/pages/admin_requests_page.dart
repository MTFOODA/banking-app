import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/labels.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/admin_requests_cubit.dart';
import 'admin_frame.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});
  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  late final _cubit = AdminRequestsCubit(sl<AdminRepository>())..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AdminFrame(
      title: l.requestQueue,
      index: 1,
      onRefresh: _cubit.load,
      child: BlocBuilder<AdminRequestsCubit, AdminRequestsState>(
        bloc: _cubit,
        builder: (context, s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              key: const ValueKey('admin_request_search'),
              onSubmitted: _cubit.searchBy,
              decoration: InputDecoration(
                labelText: l.admSearch,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: s.statusFilter ?? 'all',
              decoration: InputDecoration(labelText: l.status),
              items: [
                for (final status in [
                  'all',
                  'submitted',
                  'under_review',
                  'pending_approval',
                  'pending_customer_info',
                  'approved',
                  'completed',
                  'rejected',
                  'cancelled',
                ])
                  DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'all'
                          ? l.admAll
                          : requestStatusLabel(l, status),
                    ),
                  ),
              ],
              onChanged: (v) => _cubit.filterByStatus(v == 'all' ? null : v),
            ),
            const SizedBox(height: 16),
            if (s.loading)
              const Center(child: CircularProgressIndicator())
            else if (s.error != null) ...[
              Text(securityError(l, s.error!)),
              TextButton(onPressed: _cubit.load, child: Text(l.retry)),
            ] else ...[
              Text(
                '${s.items.length} / ${s.total}',
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              if (s.items.isEmpty) Text(l.admEmptyRequests),
              for (final item in s.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FaisalSurface(
                    onTap: () async {
                      await context.push(AppRoutes.adminRequest(item.id));
                      if (mounted) await _cubit.load();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.reference,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            FaisalStatusBadge(
                              label: requestStatusLabel(l, item.status),
                              tone: FaisalStatusBadge.toneForStatus(
                                item.status,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.customerName),
                        Text(requestTypeLabel(l, item.requestType)),
                        if (item.submittedAt != null)
                          Text(
                            item.submittedAt!
                                .toLocal()
                                .toString()
                                .split('.')
                                .first,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              if (s.actionError != null) Text(securityError(l, s.actionError!)),
              if (s.busy) const Center(child: CircularProgressIndicator()),
              if (s.hasNext)
                TextButton(
                  onPressed: s.busy ? null : _cubit.loadMore,
                  child: Text(l.admLoadMore),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
