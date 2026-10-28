import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_app_bar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.unreadCount,
    required this.onNotifications,
    required this.onLogout,
    required this.notificationsTooltip,
    required this.logoutTooltip,
  });

  final String greeting;
  final String name;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;
  final String notificationsTooltip;
  final String logoutTooltip;

  @override
  Widget build(BuildContext context) {
    return FaisalHeader(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FaisalColors.goldAccent,
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ف',
                        style: TextStyle(
                          color: BrandingScope.headerText(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        BrandingScope.of(context)
                                .text('application_short_name') ??
                            BrandingScope.of(context)
                                .text('application_name') ??
                            'Faisal App',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BrandingScope.headerText(context)
                              .withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  greeting,
                  style: TextStyle(
                    color: BrandingScope.headerText(context)
                        .withValues(alpha: 0.72),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall?.copyWith(
                    color: BrandingScope.headerText(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            tooltip: notificationsTooltip,
            badgeCount: unreadCount,
            onTap: onNotifications,
          ),
          _HeaderAction(
            icon: Icons.logout_rounded,
            tooltip: logoutTooltip,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: BrandingScope.headerText(context)),
        ),
        if (badgeCount > 0)
          PositionedDirectional(
            top: 8,
            end: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: FaisalColors.goldAccent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: FaisalColors.deepForestGreen,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
