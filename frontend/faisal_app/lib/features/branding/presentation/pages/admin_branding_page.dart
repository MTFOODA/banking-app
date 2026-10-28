import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/pages/admin_frame.dart';
import '../../domain/entities/branding_config.dart';
import '../../domain/repositories/branding_repository.dart';
import '../cubit/branding_cubit.dart';
import '../cubit/branding_editor_cubit.dart';
import '../widgets/branding_color_picker.dart';
import '../widgets/branding_image.dart';
import '../widgets/branding_preview.dart';
import '../widgets/branding_scope.dart';

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
  bool dark = false, allowPop = false;
  BrandingConfig lastValid = BrandingConfig.defaults;
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
    'restored' => l.brandingRestored,
    _ => l.brandingUploaded,
  };
  Future<void> upload(String field) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (picked == null || !mounted) {
        return;
      }
      final size = await picked.length();
      if (size == null || size > 2 * 1024 * 1024) {
        throw const FormatException();
      }
      await cubit.upload(field, await picked.readAsBytes(), picked.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).brandingUploadHelp),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocBuilder<BrandingEditorCubit, BrandingEditorState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.validConfig != null) {
          lastValid = state.validConfig!;
        }
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
                        Text(
                          '${l.brandingVersion}: ${state.document!.active.version}',
                          style: context.texts.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l.brandingDraftNotice),
                        if (state.dirty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l.brandingUnsaved,
                              style: TextStyle(color: context.colors.primary),
                            ),
                          ),
                        if (state.error != null)
                          _message(error(l, state.error!), error: true),
                        if (state.notice != null)
                          _message(notice(l, state.notice!)),
                        if (state.validConfig == null)
                          _message(l.brandingInvalid, error: true),
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
                                config: lastValid,
                                brightness: dark
                                    ? Brightness.dark
                                    : Brightness.light,
                              ),
                            ],
                          ),
                        ),
                        _section(
                          l.brandingGeneral,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _text(
                                state,
                                'application_name',
                                l.brandingName,
                                40,
                                helper: l.brandingOriginal,
                              ),
                              _text(
                                state,
                                'application_short_name',
                                l.brandingShortName,
                                20,
                              ),
                              _text(
                                state,
                                'welcome_message',
                                l.brandingWelcome,
                                160,
                              ),
                              _text(
                                state,
                                'application_tagline',
                                l.brandingTagline,
                                100,
                              ),
                              Text(
                                l.brandingUploadHelp,
                                style: context.texts.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              for (final entry in [
                                ('logo_url', l.brandingLogo),
                                ('dark_logo_url', l.brandingDarkLogo),
                                ('splash_image_url', l.brandingSplash),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        entry.$2,
                                        style: context.texts.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      BrandingScope(
                                        config: lastValid,
                                        preview: true,
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: BrandingImage(
                                            url:
                                                state.values![entry.$1]
                                                    as String?,
                                            width: 120,
                                            height: 80,
                                            label: entry.$2,
                                            fallback: const FaisalLogo(
                                              size: 60,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          TextButton.icon(
                                            onPressed: state.busy
                                                ? null
                                                : () => upload(entry.$1),
                                            icon: const Icon(
                                              Icons.upload_outlined,
                                            ),
                                            label: Text(l.brandingUpload),
                                          ),
                                          TextButton(
                                            onPressed: state.busy
                                                ? null
                                                : () => cubit.edit(
                                                    entry.$1,
                                                    null,
                                                  ),
                                            child: Text(l.brandingRemove),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _section(
                          l.brandingColors,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.brandingCustomTheme),
                                value: state.values!['custom_theme'] as bool,
                                onChanged: state.busy
                                    ? null
                                    : (v) => cubit.edit('custom_theme', v),
                              ),
                              for (final mode in ['light', 'dark']) ...[
                                const SizedBox(height: 12),
                                Text(
                                  mode == 'light'
                                      ? l.brandingLight
                                      : l.brandingDark,
                                  style: context.texts.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) => Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final entry in _colorLabels(
                                        l,
                                      ).entries)
                                        SizedBox(
                                          width: constraints.maxWidth > 620
                                              ? (constraints.maxWidth - 24) / 3
                                              : constraints.maxWidth > 420
                                              ? (constraints.maxWidth - 12) / 2
                                              : constraints.maxWidth,
                                          child: TextFormField(
                                            key: ValueKey(
                                              '${state.epoch}-$mode-${entry.key}',
                                            ),
                                            initialValue:
                                                (state.values![mode]
                                                        as Map)[entry.key]
                                                    as String,
                                            enabled: !state.busy,
                                            textDirection: TextDirection.ltr,
                                            maxLength: 7,
                                            decoration: InputDecoration(
                                              labelText: entry.value,
                                              counterText: '',
                                              suffixIcon: IconButton(
                                                tooltip: l.brandingHex,
                                                onPressed: state.busy
                                                    ? null
                                                    : () async {
                                                        final current =
                                                            (state.values![mode]
                                                                    as Map)[entry
                                                                    .key]
                                                                as String;
                                                        final picked =
                                                            await pickBrandingColor(
                                                              context,
                                                              RegExp(
                                                                    r'^#[0-9a-fA-F]{6}$',
                                                                  ).hasMatch(
                                                                    current,
                                                                  )
                                                                  ? current
                                                                  : '#075C46',
                                                            );
                                                        if (picked != null) {
                                                          cubit.edit(
                                                            entry.key,
                                                            picked,
                                                            mode: mode,
                                                            resetForm: true,
                                                          );
                                                        }
                                                      },
                                                icon: Icon(
                                                  Icons.color_lens,
                                                  color: _safeColor(
                                                    (state.values![mode]
                                                            as Map)[entry.key]
                                                        as String,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) => cubit.edit(
                                              entry.key,
                                              v.toUpperCase(),
                                              mode: mode,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
                                'primary_font',
                                l.brandingPrimaryFont,
                                brandingFonts,
                              ),
                              _dropdown(
                                state,
                                'arabic_font',
                                l.brandingArabicFont,
                                ['System', 'NotoSansArabic'],
                              ),
                              _dropdown(
                                state,
                                'english_font',
                                l.brandingEnglishFont,
                                ['System', 'NotoSans'],
                              ),
                              Text(
                                '${l.brandingScale}: ${(state.values!['font_size_scale'] as num).toStringAsFixed(2)}',
                              ),
                              Slider(
                                value: (state.values!['font_size_scale'] as num)
                                    .toDouble(),
                                min: .9,
                                max: 1.15,
                                divisions: 5,
                                semanticFormatterCallback: (v) =>
                                    '${l.brandingScale}: ${v.toStringAsFixed(2)}',
                                onChanged: state.busy
                                    ? null
                                    : (v) => cubit.edit(
                                        'font_size_scale',
                                        double.parse(v.toStringAsFixed(2)),
                                      ),
                              ),
                              _dropdown(
                                state,
                                'heading_font_weight',
                                l.brandingHeadingWeight,
                                [400, 500, 600, 700],
                              ),
                              _dropdown(
                                state,
                                'body_font_weight',
                                l.brandingBodyWeight,
                                [400, 500, 600],
                              ),
                              _dropdown(state, 'theme_mode', l.brandingMode, [
                                'user',
                                'light',
                                'dark',
                                'system',
                              ]),
                            ],
                          ),
                        ),
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
                                    await cubit.restore();
                                  }
                                },
                          child: Text(l.brandingDefaults),
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
                        _section(
                          l.brandingNative,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.brandingReleaseRequired,
                                style: context.texts.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(l.brandingNativeHelp),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _message(String message, {bool error = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(
          color: error ? context.colors.error : context.colors.primary,
        ),
      ),
    ),
  );
  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
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
    String key,
    String label,
    int max, {
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('${state.epoch}-$key'),
      initialValue: state.values![key] as String? ?? '',
      enabled: !state.busy,
      maxLength: max,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
      ),
      onChanged: (value) =>
          cubit.edit(key, value.trim().isEmpty ? null : value.trim()),
    ),
  );
  Widget _dropdown(
    BrandingEditorState state,
    String key,
    String label,
    List<Object> options,
  ) {
    final l = AppLocalizations.of(context);
    String name(Object v) => switch (v) {
      'System' => l.brandingSystemFont,
      'user' => l.brandingUserMode,
      'light' => l.brandingLight,
      'dark' => l.brandingDark,
      'system' => l.brandingSystem,
      _ => v.toString(),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<Object>(
        key: ValueKey('${state.epoch}-$key'),
        initialValue: state.values![key],
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((v) => DropdownMenuItem(value: v, child: Text(name(v))))
            .toList(),
        onChanged: state.busy ? null : (v) => cubit.edit(key, v),
      ),
    );
  }

  Color _safeColor(String value) => RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(value)
      ? BrandingConfig.parseColor(value)
      : context.colors.error;
  Map<String, String> _colorLabels(AppLocalizations l) =>
      Map.fromIterables(brandingColorKeys, [
        l.brandingPrimary,
        l.brandingSecondary,
        l.brandingAccent,
        l.brandingBackground,
        l.brandingSurface,
        l.brandingTextPrimary,
        l.brandingTextSecondary,
        l.brandingError,
        l.brandingButtonBackground,
        l.brandingButtonText,
        l.brandingCard,
        l.brandingBorder,
      ]);
}
