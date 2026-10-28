import 'package:flutter/material.dart';

import '../../../../core/localization/labels.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/discover_entities.dart';

String announcementLocationLabel(AppLocalizations l, String value) =>
    switch (value) {
      'pre_login' => l.admBeforeLogin,
      'both' => l.admBoth,
      _ => l.admHome,
    };

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.item, this.footer});
  final Announcement item;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        ar = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FaisalSurface(
        borderColor: item.priority == 'high' ? context.palette.gold : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  item.priority == 'high'
                      ? Icons.warning_amber_rounded
                      : Icons.campaign_outlined,
                  color: item.priority == 'high'
                      ? context.palette.gold
                      : context.colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title(ar),
                    style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              priorityLabel(l, item.priority),
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(item.body(ar), style: context.texts.bodyMedium),
            if (footer != null) ...[const Divider(), footer!],
          ],
        ),
      ),
    );
  }
}
