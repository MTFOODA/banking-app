import 'package:flutter/material.dart';

import '../../../../core/theme/branding_theme.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/branding_config.dart';
import 'branding_scope.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../../../core/config/banking_identity.dart';

class BrandingPreview extends StatelessWidget {
  const BrandingPreview({
    super.key,
    required this.config,
    required this.brightness,
    this.bank,
  });
  final BrandingConfig config;
  final Brightness brightness;
  final BankDefinition? bank;
  @override
  Widget build(BuildContext context) {
    final theme = BrandingTheme.build(
      config,
      brightness,
      Localizations.localeOf(context).languageCode,
    );
    final l = AppLocalizations.of(context);
    return BrandingScope(
      config: config,
      preview: true,
      bank: bank,
      child: Theme(
        data: theme,
        child: Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const FaisalLogo(size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        BankingIdentity.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (bank != null)
                  Text(
                    bank!.name(Localizations.localeOf(context).languageCode),
                    style: theme.textTheme.titleMedium,
                  ),
                Text(
                  config.text('welcome_message') ?? l.brandingPreviewBody,
                  style: theme.textTheme.headlineSmall,
                ),
                if (config.text('application_tagline')?.isNotEmpty == true)
                  Text(
                    config.text('application_tagline')!,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.brandingPreviewCard,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'English • مرحبًا بك',
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          '1,250.00 EGP',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: () {}, child: Text(l.continueLabel)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(l.brandingPreviewCard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
