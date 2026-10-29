import '../../domain/entities/bank_directory.dart';
import '../../domain/repositories/bank_directory_repository.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../../../core/widgets/faisal_logo.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/bank_contact_links.dart';

class AtmLocatorPage extends StatefulWidget {
  const AtmLocatorPage({super.key, this.bankName});
  final String? bankName;
  @override
  State<AtmLocatorPage> createState() => _AtmLocatorPageState();
}

class _AtmLocatorPageState extends State<AtmLocatorPage> {
  final _area = TextEditingController();
  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), links = sl<BankContactLinks>();
    return FaisalPage(
      title: widget.bankName == null
          ? l.publicAtms
          : '${l.publicAtms} · ${widget.bankName}',
      child: FaisalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.local_atm_outlined,
              size: 60,
              color: context.colors.primary,
            ),
            const SizedBox(height: 20),
            Text(l.publicAtmSubtitle, style: context.texts.titleLarge),
            const SizedBox(height: 12),
            Text(l.publicAtmNote),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('atm_area'),
              controller: _area,
              maxLength: 120,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l.publicAtmArea,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              onSubmitted: (_) =>
                  openBankLink(context, links, links.atmSearch(_area.text)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('atm_map_search'),
              onPressed: () {
                FocusScope.of(context).unfocus();
                openBankLink(context, links, links.atmSearch(_area.text));
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(l.publicSearchAtm),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('atm_official_locator'),
              onPressed: () =>
                  openBankLink(context, links, BankContactLinks.locator),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.publicOfficialLocator),
            ),
          ],
        ),
      ),
    );
  }
}

class CallCenterPage extends StatefulWidget {
  const CallCenterPage({super.key, this.bankName, this.bankCode = 'faisal'});
  final String? bankName;
  final String bankCode;
  @override
  State<CallCenterPage> createState() => _CallCenterPageState();
}

class _CallCenterPageState extends State<CallCenterPage> {
  BankDirectory? directory;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!sl.isRegistered<BankDirectoryRepository>()) return;
    final value = await sl<BankDirectoryRepository>().loadDirectory(
      widget.bankCode,
    );
    if (mounted) setState(() => directory = value);
    final next = await sl<BankDirectoryRepository>().loadDirectory(
      widget.bankCode,
      refresh: true,
    );
    if (mounted && !identical(value, next)) setState(() => directory = next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), links = sl<BankContactLinks>();
    // Legacy widget-only callers retain their existing Faisal contact page.
    // For every other bank an unverified phone number stays unavailable.
    final number =
        directory?.hotline ??
        (widget.bankCode == 'faisal' ? BankContactLinks.hotline : null);
    final website =
        directory?.contactUrl ??
        Uri.parse(BankCatalogue.bundled.find(widget.bankCode)!.website);
    return FaisalPage(
      title: widget.bankName == null
          ? l.publicCallCenter
          : '${l.publicCallCenter} · ${widget.bankName}',
      child: FaisalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: FaisalLogo(size: 54)),
            const SizedBox(height: 20),
            Text(
              l.publicCallEgypt,
              textAlign: TextAlign.center,
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: 12),
            if (number != null) ...[
              SelectableText(
                number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: context.texts.displayMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.publicHotlineAvailability, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('call_center_dial'),
                onPressed: () => openBankLink(
                  context,
                  links,
                  Uri(scheme: 'tel', path: number),
                ),
                icon: const Icon(Icons.call_outlined),
                label: Text(l.publicCallAction),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('call_center_copy'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: number));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.publicNumberCopied)),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l.publicCopyNumber),
              ),
            ] else
              Text(l.bankContactUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('call_center_website'),
              onPressed: () => openBankLink(context, links, website),
              icon: const Icon(Icons.language),
              label: Text(l.publicOfficialWebsite),
            ),
          ],
        ),
      ),
    );
  }
}
