import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/config/banking_identity.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/pages/admin_frame.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../../banks/presentation/bank_catalogue_cubit.dart';
import '../../../banks/presentation/bank_selector.dart';
import '../../domain/entities/branding_config.dart';
import '../../domain/repositories/branding_repository.dart';
import '../cubit/branding_cubit.dart';
import '../cubit/branding_editor_cubit.dart';
import '../widgets/branding_preview.dart';

class AdminBrandingPage extends StatefulWidget {
  const AdminBrandingPage({super.key, this.repository, this.onPublished});
  final BrandingRepository? repository;
  final Future<void> Function()? onPublished;
  @override
  State<AdminBrandingPage> createState() => _AdminBrandingPageState();
}

class _AdminBrandingPageState extends State<AdminBrandingPage> {
  late final cubit = BrandingEditorCubit(
    widget.repository ?? sl<BrandingRepository>(),
    onPublished:
        widget.onPublished ?? () => sl<BrandingCubit>().refresh(force: true),
  )..load();
  String bankCode = 'faisal';
  bool dark = false, allowPop = false;
  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> reload() async {
    if (!cubit.state.dirty ||
        await confirm(AppLocalizations.of(context).brandingReloadConfirm)) {
      await cubit.load();
    }
  }

  String error(AppLocalizations l, String code) => switch (code) {
    'conflict' => l.brandingConflict,
    'invalid' => l.brandingInvalid,
    'saveFirst' => l.brandingSaveFirst,
    'history' => l.brandingHistoryFailed,
    _ => l.brandingRequestFailed,
  };
  String notice(AppLocalizations l, String code) => switch (code) {
    'saved' => l.brandingSaved,
    'published' => l.brandingPublished,
    _ => l.brandingRestored,
  };
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocBuilder<BrandingEditorCubit, BrandingEditorState>(
      bloc: cubit,
      builder: (context, state) {
        final catalogue = sl.isRegistered<BankCatalogueCubit>()
            ? sl<BankCatalogueCubit>().state
            : BankCatalogue.bundled;
        final bank =
            catalogue.find(bankCode) ?? BankCatalogue.bundled.find('faisal')!;
        final root =
            state.validConfig ??
            state.document?.active.config ??
            BrandingConfig.defaults;
        final effective = root.forBank(bank);
        final overrides = state.values?['bank_overrides'] as Map?;
        final raw = overrides?[bankCode];
        final values = raw is Map
            ? raw
            : <String, dynamic>{
                for (final key in bankAppearanceKeys)
                  key: state.values?[key] ?? BrandingConfig.defaults.data[key],
              };
        final epoch = '${state.epoch}-$bankCode';
        return PopScope(
          canPop: !state.dirty || allowPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            if (await confirm(l.brandingUnsaved) && mounted) {
              setState(() => allowPop = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.pop();
                }
              });
            }
          },
          child: AdminFrame(
            title: l.brandingTitle,
            back: true,
            onRefresh: state.busy ? null : reload,
            child: state.document == null
                ? Center(
                    child: state.busy
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(error(l, state.error ?? 'request')),
                              TextButton(
                                onPressed: cubit.load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.busy) const LinearProgressIndicator(),
                        _section(
                          l.bankFixedIdentity,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FaisalLogo(size: 48, showWordmark: true),
                              const SizedBox(height: 12),
                              Text(l.bankFixedIdentityHelp),
                              const SizedBox(height: 8),
                              Text(
                                BankingIdentity.name,
                                style: context.texts.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${l.brandingVersion}: ${state.document!.active.version}',
                          style: context.texts.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        BankSelector(
                          value: bankCode,
                          enabled: !state.busy,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => bankCode = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(l.bankAppearanceScope),
                        if (state.dirty) _message(l.brandingUnsaved),
                        if (state.error != null)
                          _message(error(l, state.error!), bad: true),
                        if (state.notice != null)
                          _message(notice(l, state.notice!)),
                        if (state.validConfig == null)
                          _message(l.brandingInvalid, bad: true),
                        _section(
                          l.brandingPreview,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                    value: false,
                                    label: Text(l.brandingLight),
                                    icon: const Icon(Icons.light_mode_outlined),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text(l.brandingDark),
                                    icon: const Icon(Icons.dark_mode_outlined),
                                  ),
                                ],
                                selected: {dark},
                                onSelectionChanged: (value) =>
                                    setState(() => dark = value.first),
                              ),
                              const SizedBox(height: 12),
                              BrandingPreview(
                                config: effective,
                                bank: bank,
                                brightness: dark
                                    ? Brightness.dark
                                    : Brightness.light,
                              ),
                            ],
                          ),
                        ),
                        _section(
                          l.bankPresetColors,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l.bankPresetHelp),
                              const SizedBox(height: 12),
                              for (final mode in ['light', 'dark']) ...[
                                Text(
                                  mode == 'light'
                                      ? l.brandingLight
                                      : l.brandingDark,
                                  style: context.texts.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final entry
                                        in (mode == 'light'
                                                ? bank.light
                                                : bank.dark)
                                            .entries)
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor:
                                              BrandingConfig.parseColor(
                                                entry.value,
                                              ),
                                        ),
                                        label: Text(
                                          '${colorLabel(l, entry.key)}: ${entry.value}',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        _section(
                          l.bankInternalContent,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _text(
                                state,
                                epoch,
                                values,
                                'welcome_message',
                                l.brandingWelcome,
                                160,
                              ),
                              _text(
                                state,
                                epoch,
                                values,
                                'application_tagline',
                                l.bankInternalCaption,
                                100,
                              ),
                            ],
                          ),
                        ),
                        _section(
                          l.brandingTypography,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'primary_font',
                                l.brandingPrimaryFont,
                                brandingFonts,
                              ),
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'arabic_font',
                                l.brandingArabicFont,
                                ['System', 'NotoSansArabic'],
                              ),
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'english_font',
                                l.brandingEnglishFont,
                                ['System', 'NotoSans'],
                              ),
                              Text(
                                '${l.brandingScale}: ${(values['font_size_scale'] as num).toStringAsFixed(2)}',
                              ),
                              Slider(
                                value: (values['font_size_scale'] as num)
                                    .toDouble(),
                                min: .9,
                                max: 1.15,
                                divisions: 5,
                                semanticFormatterCallback: (v) =>
                                    '${l.brandingScale}: ${v.toStringAsFixed(2)}',
                                onChanged: state.busy
                                    ? null
                                    : (v) => cubit.editBank(
                                        bankCode,
                                        'font_size_scale',
                                        double.parse(v.toStringAsFixed(2)),
                                      ),
                              ),
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'heading_font_weight',
                                l.brandingHeadingWeight,
                                [400, 500, 600, 700],
                              ),
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'body_font_weight',
                                l.brandingBodyWeight,
                                [400, 500, 600],
                              ),
                              _dropdown(
                                state,
                                epoch,
                                values,
                                'theme_mode',
                                l.brandingMode,
                                ['user', 'light', 'dark', 'system'],
                              ),
                            ],
                          ),
                        ),
                        Text(l.brandingDraftNotice),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 240,
                              child: FilledButton.icon(
                                key: const Key('branding-save'),
                                onPressed:
                                    state.busy ||
                                        !state.dirty ||
                                        state.validConfig == null
                                    ? null
                                    : cubit.save,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(l.brandingSave),
                              ),
                            ),
                            SizedBox(
                              width: 240,
                              child: FilledButton.icon(
                                key: const Key('branding-publish'),
                                onPressed:
                                    state.busy ||
                                        state.dirty ||
                                        state.document!.draft == null
                                    ? null
                                    : () async {
                                        if (await confirm(
                                          l.brandingPublishConfirm,
                                        )) {
                                          await cubit.publish();
                                        }
                                      },
                                icon: const Icon(Icons.publish),
                                label: Text(l.brandingPublish),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () async {
                                  if (await confirm(l.brandingReplaceConfirm)) {
                                    await cubit.restore(bankCode: bankCode);
                                  }
                                },
                          child: Text(l.bankRestorePreset),
                        ),
                        _section(
                          l.brandingHistory,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.history.isEmpty)
                                Text(l.brandingNoHistory),
                              for (final entry in state.history)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${l.brandingVersion} ${entry.version}',
                                  ),
                                  subtitle: Text(
                                    entry.publishedAt
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                  ),
                                  trailing: TextButton(
                                    onPressed: state.busy
                                        ? null
                                        : () async {
                                            if (await confirm(
                                              l.brandingReplaceConfirm,
                                            )) {
                                              await cubit.restore(
                                                version: entry.version,
                                                bankCode: bankCode,
                                              );
                                            }
                                          },
                                    child: Text(l.brandingRestore),
                                  ),
                                ),
                              if (state.moreHistory)
                                TextButton(
                                  onPressed: state.busy ? null : cubit.more,
                                  child: Text(l.brandingMoreHistory),
                                ),
                            ],
                          ),
                        ),
                        _section(l.brandingNative, Text(l.brandingNativeHelp)),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _message(String value, {bool bad = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Semantics(
      liveRegion: true,
      child: Text(
        value,
        style: TextStyle(
          color: bad ? context.colors.error : context.colors.primary,
        ),
      ),
    ),
  );
  String colorLabel(AppLocalizations l, String key) => switch (key) {
    'primary' => l.brandingPrimary,
    'secondary' => l.brandingSecondary,
    'accent' => l.brandingAccent,
    'background' => l.brandingBackground,
    'surface' => l.brandingSurface,
    'text_primary' => l.brandingTextPrimary,
    'text_secondary' => l.brandingTextSecondary,
    'error' => l.brandingError,
    'button_background' => l.brandingButtonBackground,
    'button_text' => l.brandingButtonText,
    'card' => l.brandingCard,
    'border' => l.brandingBorder,
    _ => key,
  };
  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.texts.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
  Widget _text(
    BrandingEditorState state,
    String epoch,
    Map values,
    String key,
    String label,
    int max,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('$epoch-$key'),
      initialValue: values[key] as String? ?? '',
      enabled: !state.busy,
      maxLength: max,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) =>
          cubit.editBank(bankCode, key, v.trim().isEmpty ? null : v.trim()),
    ),
  );
  Widget _dropdown(
    BrandingEditorState state,
    String epoch,
    Map values,
    String key,
    String label,
    List<Object> options,
  ) {
    final l = AppLocalizations.of(context);
    String name(Object value) => switch (value) {
      'System' => l.brandingSystemFont,
      'user' => l.brandingUserMode,
      'light' => l.brandingLight,
      'dark' => l.brandingDark,
      'system' => l.brandingSystem,
      _ => value.toString(),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<Object>(
        key: ValueKey('$epoch-$key'),
        initialValue: values[key],
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((v) => DropdownMenuItem(value: v, child: Text(name(v))))
            .toList(),
        onChanged: state.busy ? null : (v) => cubit.editBank(bankCode, key, v),
      ),
    );
  }
}
