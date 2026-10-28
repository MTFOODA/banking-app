import '../../../../core/config/banking_identity.dart';
import '../../../../core/widgets/faisal_logo.dart';
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
                    const FaisalLogo(size: 34, onDark: true),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        BankingIdentity.name,
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
                if (BrandingScope.bankOf(context) != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    BrandingScope.bankOf(context)!
                        .name(Localizations.localeOf(context).languageCode),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.onHeaderMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  BrandingScope.of(context).text('welcome_message') ?? greeting,
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
                if (BrandingScope.of(context)
                        .text('application_tagline')
                        ?.isNotEmpty ==
                    true)
                  Text(
                    BrandingScope.of(context).text('application_tagline')!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.onHeaderMuted,
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
