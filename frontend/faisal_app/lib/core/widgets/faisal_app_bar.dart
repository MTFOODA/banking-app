import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/faisal_palette.dart';

/// Deep-green header used on Login, Home, Accounts and Cards.
class FaisalHeader extends StatelessWidget {
  const FaisalHeader({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
    this.showGoldDecoration = true,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool showGoldDecoration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: Container(
        height: height,
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.palette.headerGradient,
          ),
        ),
        child: Stack(
          children: [
            if (showGoldDecoration) ...[
              Positioned(
                right: -40,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FaisalColors.goldAccent.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -70,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FaisalColors.goldAccent.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Simple standard app bar matching the design system.
class FaisalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FaisalAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.showBackButton = true,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
