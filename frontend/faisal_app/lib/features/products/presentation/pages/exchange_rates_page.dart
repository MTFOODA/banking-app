import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/investment_repository.dart';
import '../cubit/exchange_rates_cubit.dart';
import 'exchange_rate_card.dart';

class ExchangeRatesPage extends StatefulWidget {
  const ExchangeRatesPage({super.key});
  @override
  State<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends State<ExchangeRatesPage>
    with WidgetsBindingObserver {
  late final _cubit = ExchangeRatesCubit(sl<InvestmentRepository>())..start();
  final _search = TextEditingController();
  static const _favoriteKey = 'faisal.fx_favorites';
  static const _arab = {'SAR', 'AED', 'KWD', 'QAR'};
  late final Set<String> _favorites =
      (sl.isRegistered<SharedPreferences>()
              ? sl<SharedPreferences>().getStringList(_favoriteKey) ??
                    ['USD', 'SAR', 'EUR']
              : ['USD', 'SAR', 'EUR'])
          .toSet();
  String _filter = 'all';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.start();
    } else {
      _cubit.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _favorite(String code) async {
    setState(() {
      if (!_favorites.add(code)) _favorites.remove(code);
    });
    if (sl.isRegistered<SharedPreferences>()) {
      await sl<SharedPreferences>().setStringList(
        _favoriteKey,
        _favorites.toList(),
      );
    }
  }

  String _date(Object? value) =>
      DateTime.tryParse('$value')?.toLocal().toString().split('.').first ??
      '$value';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.exchangeRatesTitle),
        actions: [
          IconButton(
            tooltip: l.retry,
            onPressed: _cubit.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ExchangeRatesCubit, ExchangeRatesState>(
        bloc: _cubit,
        builder: (context, s) {
          final data = s.rates?.data;
          final all = s.rates?.rates ?? <Map<String, dynamic>>[];
          final query = _search.text.trim().toLowerCase();
          final rows = all.where((row) {
            final code = '${row['currency']}';
            final matches = switch (_filter) {
              'favorites' => _favorites.contains(code),
              'arab' => _arab.contains(code),
              'foreign' => !_arab.contains(code),
              _ => true,
            };
            return matches &&
                ('$code ${currencyName(l, code)} ${currencySearchNames(code)}'
                    .toLowerCase()
                    .contains(query));
          }).toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _search,
                    key: const ValueKey('fx_search'),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l.fxSearch,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in [
                          ('all', '${l.fxAll} (${all.length})'),
                          (
                            'favorites',
                            '${l.fxFavorites} (${all.where((r) => _favorites.contains(r['currency'])).length})',
                          ),
                          ('arab', l.fxArabCurrencies),
                          ('foreign', l.fxForeignCurrencies),
                        ])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              key: ValueKey('fx_filter_${item.$1}'),
                              label: Text(item.$2),
                              selected: _filter == item.$1,
                              onSelected: (_) =>
                                  setState(() => _filter = item.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.fxEgpBase,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onPrimary),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l.fxRefreshNotice.split('.').first,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (s.loading) const LinearProgressIndicator(),
                  if (s.error != null) ...[
                    Text(securityError(l, s.error!)),
                    TextButton(onPressed: _cubit.load, child: Text(l.retry)),
                  ],
                  if (data?['stale'] == true ||
                      (data != null && s.error != null))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l.fxStale,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  if (!s.loading && data != null && rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l.fxEmpty, textAlign: TextAlign.center),
                    ),
                  for (final row in rows)
                    ExchangeRateCard(
                      row: row,
                      favorite: _favorites.contains(row['currency']),
                      onFavorite: () => _favorite('${row['currency']}'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l.fxIndicativeNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (data != null)
                    ExpansionTile(
                      title: Text(l.fxDetails),
                      children: [
                        for (final text in [
                          '${l.fxProviderTime}: ${_date(data['provider_updated_at'])}',
                          '${l.fxFetchedTime}: ${_date(data['fetched_at'])}',
                          '${l.fxDelaySeconds}: ${data['delay_seconds']}',
                          '${l.fxSpread}: ${data['spread_bps']} bps',
                          data['market_session'] == 'open'
                              ? l.fxMarketOpen
                              : l.fxMarketClosed,
                          l.fxRefreshNotice,
                        ])
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(text),
                          ),
                      ],
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.fxAttribution),
                    onPressed: () async {
                      var opened = false;
                      try {
                        opened = await launchUrl(
                          Uri.parse('https://exchangerate.dev'),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        /* Recoverable failure. */
                      }
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.securityOperationError)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
