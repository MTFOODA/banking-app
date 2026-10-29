import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/pages/login_widgets.dart';
import '../../../settings/presentation/cubit/appearance_cubits.dart';
import '../../domain/repositories/discover_repository.dart';
import '../cubit/announcement_reader_cubit.dart';
import '../widgets/announcement_card.dart';
import '../widgets/public_service_cards.dart';

class BankNoticesPage extends StatefulWidget {
  const BankNoticesPage({super.key, this.id});
  final String? id;
  @override
  State<BankNoticesPage> createState() => _BankNoticesPageState();
}

class _BankNoticesPageState extends State<BankNoticesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.id == null) {
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      }
    });
  }

  late final _cubit = AnnouncementReaderCubit(
    sl<DiscoverRepository>(),
    id: widget.id,
    bankCode: BrandingScope.bankOf(context)?.code,
  )..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.softSurface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cubit.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                FaisalHeader(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (widget.id != null)
                            IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              onPressed: () => context.pop(),
                              icon: Icon(
                                Icons.arrow_back,
                                color: context.palette.onHeader,
                              ),
                            ),
                          const FaisalLogo(size: 42, onDark: true),
                          const Spacer(),
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
                          FaisalLanguageToggle(
                            languageCode: Localizations.localeOf(context)
                                .languageCode,
                            onChanged: context.read<LanguageCubit>().change,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.id == null
                            ? l.publicWelcomeTitle
                            : l.admPublicTitle,
                        style: context.texts.headlineMedium?.copyWith(
                          color: context.palette.onHeader,
                        ),
                      ),
                      if (widget.id == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.publicWelcomeSubtitle,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.palette.onHeaderMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.id == null) ...[
                            const PublicServiceCards(),
                            const SizedBox(height: 28),
                            Text(
                              l.admPublicTitle,
                              style: context.texts.titleLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          BlocBuilder<
                            AnnouncementReaderCubit,
                            AnnouncementReaderState
                          >(
                            bloc: _cubit,
                            builder: (context, s) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (s.loading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                if (s.error != null) ...[
                                  Text(securityError(l, s.error!)),
                                  TextButton(
                                    onPressed: _cubit.load,
                                    child: Text(l.retry),
                                  ),
                                ],
                                if (!s.loading &&
                                    s.error == null &&
                                    s.items.isEmpty)
                                  Text(l.admPublicEmpty),
                                for (final item in s.items)
                                  AnnouncementCard(item: item),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
