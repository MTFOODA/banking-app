import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/pages/login_widgets.dart';
import '../../../settings/presentation/cubit/appearance_cubits.dart';

class AdminFrame extends StatelessWidget {
  const AdminFrame({
    super.key,
    required this.title,
    required this.child,
    this.index = 0,
    this.back = false,
    this.onRefresh,
  });
  final String title;
  final Widget child;
  final int index;
  final bool back;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.softSurface,
      body: SafeArea(
        child: Column(
          children: [
            FaisalHeader(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (back)
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: context.palette.onHeader,
                          ),
                        ),
                      const FaisalLogo(size: 38, onDark: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.adminPortal,
                          style: context.texts.titleMedium?.copyWith(
                            color: context.palette.onHeader,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.theme,
                        onPressed: () => context.read<ThemeCubit>().change(
                          Theme.of(context).brightness == Brightness.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        ),
                        icon: Icon(
                          Icons.brightness_6_outlined,
                          color: context.palette.onHeader,
                        ),
                      ),
                      IconButton(
                        tooltip: l.signOut,
                        onPressed: () => context.read<AuthBloc>().add(
                          const AuthLogoutRequested(),
                        ),
                        icon: Icon(
                          Icons.logout,
                          color: context.palette.onHeader,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: context.texts.headlineSmall?.copyWith(
                            color: context.palette.onHeader,
                          ),
                        ),
                      ),
                      FaisalLanguageToggle(
                        languageCode: Localizations.localeOf(context)
                            .languageCode,
                        onChanged: context.read<LanguageCubit>().change,
                      ),
                      if (onRefresh != null)
                        IconButton(
                          tooltip: l.retry,
                          onPressed: onRefresh,
                          icon: Icon(
                            Icons.refresh,
                            color: context.palette.onHeader,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.admSubtitle,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.palette.onHeaderMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: back
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(
                [
                  AppRoutes.admin,
                  AppRoutes.adminRequests,
                  AppRoutes.adminAnnouncements,
                ][i],
              ),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: l.dashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: l.requestQueue,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.campaign_outlined),
                  label: l.announcementsAdmin,
                ),
              ],
            ),
    );
  }
}
