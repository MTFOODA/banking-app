import '../../features/banks/presentation/bank_logo.dart';

import 'package:flutter/material.dart';

import '../config/banking_identity.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import '../../features/branding/presentation/widgets/branding_scope.dart';

/// Reviewed bank identity follows the current scope; native branding stays compiled.
class FaisalLogo extends StatelessWidget {
  const FaisalLogo({
    super.key,
    this.size = 48,
    this.onDark,
    this.showWordmark = false,
  });
  static const String assetPath = BankingIdentity.logo;
  final double size;
  final bool? onDark;
  final bool showWordmark;
  @override
  Widget build(BuildContext context) {
    final bank = BrandingScope.bankOf(context);
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    final color = dark
        ? BrandingScope.headerText(context)
        : context.colors.onSurface;
    final muted = dark
        ? context.palette.onHeaderMuted
        : context.colors.onSurfaceVariant;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bank != null)
          BankLogo(bank: bank, size: size)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(size * .24),
            child: ColoredBox(
              color: Colors.white,
              child: Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: BankingIdentity.displayName(context),
              ),
            ),
          ),
        if (showWordmark) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BankingIdentity.displayName(context),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: color,
                    ),
                  ),
                  if (bank == null)
                    Text(
                      arabic ? 'بنوكك في تطبيق واحد' : 'Your banks, one app',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
