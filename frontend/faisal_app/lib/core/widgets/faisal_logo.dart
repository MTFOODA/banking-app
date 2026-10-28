import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import '../../features/branding/presentation/widgets/branding_scope.dart';
import '../../features/branding/presentation/widgets/branding_image.dart';

/// Bank brand mark rendered from the project's original logo artwork.
///
/// The image is bundled at [assetPath] (`assets/branding/logo.png`) and is
/// derived from the repository's `logo.jpg` by
/// `scripts/generate_brand_assets.ps1`. The artwork is never recoloured,
/// stretched or cropped at runtime.
///
/// The wordmark colours are resolved from the active [ColorScheme] unless
/// [onDark] is provided explicitly, so the text always contrasts with the
/// surface it is painted on (light theme → dark text, dark theme → light text).
class FaisalLogo extends StatelessWidget {
  const FaisalLogo({
    super.key,
    this.size = 48,
    this.onDark,
    this.showWordmark = false,
  });

  /// Bundled brand asset (also declared in `pubspec.yaml`).
  static const String assetPath = 'assets/branding/logo.png';

  final double size;

  /// Forces the light-on-dark palette (for the deep-green header gradient).
  /// When null, it is inferred from [ThemeData.brightness].
  final bool? onDark;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final branding = BrandingScope.of(context);
    final isOnDark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    final wordmarkColor = isOnDark
        ? BrandingScope.headerText(context)
        : context.colors.onSurface;
    final taglineColor = isOnDark
        ? palette.onHeaderMuted
        : context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: BrandingImage(
            url: isOnDark
                ? branding.text('dark_logo_url') ?? branding.text('logo_url')
                : branding.text('logo_url'),
            width: size,
            height: size,
            label: '${branding.text('application_name') ?? 'Faisal App'} logo',
            fallback: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Faisal App logo',
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  branding.text('application_name') ?? 'Faisal App',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: wordmarkColor,
                  ),
                ),
                Text(
                  branding.text('application_tagline') ?? 'فيصل',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: taglineColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
