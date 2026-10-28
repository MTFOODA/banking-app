import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ExchangeRateCard extends StatelessWidget {
  const ExchangeRateCard({
    super.key,
    required this.row,
    required this.favorite,
    required this.onFavorite,
  });
  final Map<String, dynamic> row;
  final bool favorite;
  final VoidCallback onFavorite;
  String _price(Object? v) => double.tryParse('$v')?.toStringAsFixed(2) ?? '—';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    final code = '${row['currency']}';
    return Card(
      key: ValueKey('fx_card_$code'),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(switch (code) {
                    'USD' => 'US',
                    'EUR' => 'EU',
                    'SAR' => 'SA',
                    'AED' => 'AE',
                    'GBP' => 'GB',
                    'KWD' => 'KW',
                    'QAR' => 'QA',
                    _ => 'CH',
                  }, style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyName(l, code),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 $code = ${_price(row['mid'])} EGP',
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('fx_favorite_$code'),
                  tooltip: favorite ? l.fxFavoriteRemove : l.fxFavoriteAdd,
                  onPressed: onFavorite,
                  icon: Icon(
                    favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: favorite ? const Color(0xFFE4AF32) : colors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // No provider history is available: never invent a sparkline or 24h percentage.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.fxDayChangeUnavailable,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final quote in [
                  (l.fxBuy, row['buy']),
                  (l.fxSell, row['sell']),
                ]) ...[
                  if (quote.$1 == l.fxSell) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: .035),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            quote.$1,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_price(quote.$2)} EGP',
                            textDirection: TextDirection.ltr,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String currencyName(AppLocalizations l, String code) => switch (code) {
  'USD' => l.currencyUsd,
  'SAR' => l.currencySar,
  'EUR' => l.currencyEur,
  'AED' => l.currencyAed,
  'GBP' => l.currencyGbp,
  'KWD' => l.currencyKwd,
  'QAR' => l.currencyQar,
  _ => l.currencyChf,
};
String currencySearchNames(String code) => switch (code) {
  'USD' => 'US dollar دولار أمريكي',
  'SAR' => 'Saudi riyal ريال سعودي',
  'EUR' => 'Euro يورو أوروبي',
  'AED' => 'UAE dirham درهم إماراتي',
  'GBP' => 'Pound sterling جنيه إسترليني',
  'KWD' => 'Kuwaiti dinar دينار كويتي',
  'QAR' => 'Qatari riyal ريال قطري',
  _ => 'Swiss franc فرنك سويسري',
};
