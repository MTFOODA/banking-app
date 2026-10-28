import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/discover_entities.dart';
import '../../../products/presentation/widgets/announcement_card.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/admin_content_cubit.dart';
import 'admin_frame.dart';
import 'admin_announcement_form.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});
  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  late final _cubit = AdminContentCubit(sl<AdminRepository>())
    ..loadAnnouncements();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _edit([Announcement? item]) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AdminAnnouncementForm(
        initial: item,
        onSave: (payload) => item == null
            ? _cubit.createAnnouncement(payload)
            : _cubit.updateAnnouncement(item.id, payload),
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).admSaved)),
      );
    }
  }

  Future<void> _archive(String id) async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.admArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.archive),
          ),
        ],
      ),
    );
    if (yes == true) await _cubit.archive(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AdminFrame(
      title: l.announcementsAdmin,
      index: 2,
      onRefresh: _cubit.loadAnnouncements,
      child: BlocBuilder<AdminContentCubit, AdminContentState>(
        bloc: _cubit,
        builder: (context, s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('admin_new_announcement'),
                onPressed: s.busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(l.createAnnouncement),
              ),
            ),
            const SizedBox(height: 16),
            if (s.loading)
              const Center(child: CircularProgressIndicator())
            else if (s.error != null) ...[
              Text(securityError(l, s.error!)),
              TextButton(
                onPressed: _cubit.loadAnnouncements,
                child: Text(l.retry),
              ),
            ] else if (s.announcements.isEmpty)
              Text(l.admEmptyNotices),
            if (s.actionError != null) Text(securityError(l, s.actionError!)),
            for (final item in s.announcements)
              AnnouncementCard(
                item: item,
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${switch (item.status) {
                        'draft' => l.admDraft,
                        'published' => l.admPublished,
                        'archived' => l.admArchived,
                        _ => item.status,
                      }} · ${announcementLocationLabel(l, item.displayLocation)}',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: s.busy ? null : () => _edit(item),
                          child: Text(l.admEdit),
                        ),
                        if (item.status == 'draft')
                          TextButton(
                            onPressed: s.busy ? null : () => _edit(item),
                            child: Text(l.publish),
                          ),
                        if (item.status != 'archived')
                          TextButton(
                            onPressed: s.busy ? null : () => _archive(item.id),
                            child: Text(l.archive),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
