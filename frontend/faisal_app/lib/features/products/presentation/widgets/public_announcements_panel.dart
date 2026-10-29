import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/discover_repository.dart';
import '../cubit/announcement_reader_cubit.dart';
import 'announcement_card.dart';

/// Uses the existing public announcement API; never loads customer-only notices.
class PublicAnnouncementsPanel extends StatefulWidget {
  const PublicAnnouncementsPanel({super.key});
  @override
  State<PublicAnnouncementsPanel> createState() =>
      _PublicAnnouncementsPanelState();
}

class _PublicAnnouncementsPanelState extends State<PublicAnnouncementsPanel> {
  AnnouncementReaderCubit? cubit;
  String? bankCode;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = BrandingScope.bankOf(context)?.code;
    if (cubit != null && next == bankCode) return;
    cubit?.close();
    bankCode = next;
    if (sl.isRegistered<DiscoverRepository>()) {
      cubit = AnnouncementReaderCubit(sl<DiscoverRepository>(), bankCode: next)
        ..load();
    }
  }

  @override
  void dispose() {
    cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (cubit == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.admPublicTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        BlocBuilder<AnnouncementReaderCubit, AnnouncementReaderState>(
          bloc: cubit,
          builder: (context, s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.loading) const Center(child: CircularProgressIndicator()),
              if (s.error != null) ...[
                Text(securityError(l, s.error!)),
                TextButton(onPressed: cubit!.load, child: Text(l.retry)),
              ],
              if (!s.loading && s.error == null && s.items.isEmpty)
                Text(l.admPublicEmpty),
              for (final item in s.items) AnnouncementCard(item: item),
            ],
          ),
        ),
      ],
    );
  }
}
