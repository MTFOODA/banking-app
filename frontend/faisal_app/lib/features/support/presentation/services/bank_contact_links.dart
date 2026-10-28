import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Uses the device browser/maps/dialer, never places a call automatically.
class BankContactLinks {
  static const hotline = '19851';
  static final website = Uri.https('www.faisalbank.com.eg', '/ar');
  static final locator = Uri.https('www.faisalbank.com.eg', '/ar/Branches');
  Uri atmSearch(String area) => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': 'Faisal Islamic Bank ATM ${area.trim()}',
  });
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

Future<void> openBankLink(
  BuildContext context,
  BankContactLinks links,
  Uri uri,
) async {
  final opened = await links.open(uri);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).publicLinkFailed)),
    );
  }
}
