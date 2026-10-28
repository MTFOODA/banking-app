import 'package:flutter/material.dart';

import '../../features/branding/presentation/widgets/branding_scope.dart';
import '../../features/branding/domain/entities/branding_config.dart';

import '../../features/cards/domain/entities/card_entities.dart';
import '../../l10n/app_localizations.dart';
import '../localization/labels.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/faisal_palette.dart';
import '../utils/formatters.dart';
import 'faisal_status_badge.dart';
import 'card_artwork.dart';
import 'faisal_logo.dart';

/// Premium deep-green bank card visual with gold accents.
class FaisalBankCard extends StatelessWidget {
  const FaisalBankCard({
    super.key,
    required this.card,
    this.onTap,
    this.compact = false,
  });

  final BankCard card;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final radius = BorderRadius.circular(AppRadius.xl);
    final bank = BrandingScope.bankOf(context);
    final bankPrimary = bank == null || bank.code == 'faisal'
        ? null
        : BrandingConfig.parseColor(bank.light['primary']!);
    final bankAccent = bank == null || bank.code == 'faisal'
        ? null
        : BrandingConfig.parseColor(bank.light['accent']!);
    final variant = cardVariant(
      card.productCode.isEmpty && card.isCredit
          ? 'CP-PLATINUM-CREDIT'
          : card.productCode,
    );
    return Semantics(
      label:
          '${l10n.cardEndingIn(card.last4)} — ${l10n.cardHolder}: ${card.cardholderName}',
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: cardGradient(
                variant,
                primary: bankPrimary,
                accent: bankAccent,
              ),
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: CardArtwork(variant)),
                  ),
                  Positioned(
                    right: -30,
                    top: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.palette.gold.withValues(alpha: 0.22),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: -60,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.palette.gold.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      compact ? AppSpacing.lg : AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: compact ? 30 : 36,
                              height: compact ? 22 : 26,
                              decoration: BoxDecoration(
                                gradient: FaisalGradients.goldSheen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const FaisalLogo(size: 26, onDark: true),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                card.productName(arabic: arabic),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: FaisalColors.white.withValues(
                                    alpha: 0.92,
                                  ),
                                  fontSize: compact ? 11 : 12.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        Text(
                          FaisalFormatters.maskCard(card.last4),
                          style: TextStyle(
                            color: FaisalColors.white,
                            fontSize: compact ? 16 : 19,
                            letterSpacing: compact ? 1.6 : 2.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.md : AppSpacing.lg,
                        ),
                        _CardFooter(card: card, compact: compact),
                        if (card.currency != null)
                          Text(
                            card.currency!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        if (card.status == 'pending_activation') ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.cardPendingActivation,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                        if (card.isInactive) ...[
                          const SizedBox(height: AppSpacing.md),
                          FaisalStatusBadge(
                            label: cardStatusLabel(l10n, card.status),
                            tone: FaisalStatusTone.danger,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
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

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.card, required this.compact});

  final BankCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cardHolder.toUpperCase(),
                style: TextStyle(
                  color: FaisalColors.white.withValues(alpha: 0.55),
                  fontSize: 8.5,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.cardholderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FaisalColors.white,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.cardExpires(
                card.expiryMonth.toString().padLeft(2, '0'),
                card.expiryYear.toString().substring(2),
              ),
              style: TextStyle(
                color: FaisalColors.white.withValues(alpha: 0.8),
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  (card.network ?? 'DEMO').toUpperCase(),
                  style: TextStyle(
                    color: context.palette.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (card.isSupplementary) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${l10n.supplementaryCard}',
                    style: TextStyle(
                      color: FaisalColors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
