import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_entities.dart';

class FeaturedBannerStrip extends StatelessWidget {
  const FeaturedBannerStrip({
    super.key,
    required this.banners,
    required this.onBannerTap,
  });

  final List<FeaturedBanner> banners;
  final ValueChanged<FeaturedBanner> onBannerTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final banner = banners[index];
          final isMaintenance = banner.category == 'maintenance';
          return SizedBox(
            width: 280,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                onTap: () => onBannerTap(banner),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isMaintenance
                        ? context.palette.warning.withValues(alpha: 0.1)
                        : context.palette.mintSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isMaintenance
                          ? context.palette.warning.withValues(alpha: 0.45)
                          : context.palette.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMaintenance
                                ? Icons.build_circle_outlined
                                : Icons.campaign_outlined,
                            size: 18,
                            color: isMaintenance
                                ? context.palette.warning
                                : context.colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isMaintenance
                                  ? l10n.maintenanceNotice
                                  : l10n.featured,
                              style: context.texts.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        banner.title(arabic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          banner.body(arabic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (banner.ctaLabel(arabic) != null)
                        Text(
                          banner.ctaLabel(arabic)!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
