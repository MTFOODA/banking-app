import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Render only for the server's explicitly opted-in development adapter.
class DevelopmentOtpPanel extends StatelessWidget {
  const DevelopmentOtpPanel({super.key, this.code});
  final String? code;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: const ValueKey('development_otp_panel'),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.developmentCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (code != null)
                    SelectableText(
                      code!,
                      key: const ValueKey('development_otp_code'),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  else
                    Text(l.otpDevelopmentUnavailable),
                  const SizedBox(height: 4),
                  Text(
                    l.otpDevelopmentNotice,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
