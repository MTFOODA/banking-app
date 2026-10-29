import 'package:flutter/widgets.dart';

import '../../features/branding/presentation/widgets/branding_scope.dart';
import '../../l10n/app_localizations.dart';

/// Compiled identity. Remote appearance settings never override these values.
class BankingIdentity {
  const BankingIdentity._();
  static String displayName(BuildContext context) =>
      BrandingScope.bankOf(context)
          ?.name(Localizations.localeOf(context).languageCode) ??
      (Localizations.of<AppLocalizations>(context, AppLocalizations)?.appName ??
          'Your banks');
  static const name = 'Banking App';
  static const logo = 'assets/branding/banking_app_logo_master.png';
}
