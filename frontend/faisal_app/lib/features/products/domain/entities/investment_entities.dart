/// Server-calculated investment amounts remain decimal strings throughout review.
class InvestmentRecord {
  InvestmentRecord(Map<String, dynamic> value) : data = Map.unmodifiable(value);
  final Map<String, dynamic> data;
  String text(String key) => data[key]?.toString() ?? '';
  String name(bool arabic) => text(arabic ? 'name_ar' : 'name_en');
  String get id => text('id');
  bool get active => text('status') == 'active';
}

class ExchangeRates {
  ExchangeRates(Map<String, dynamic> value) : data = Map.unmodifiable(value);
  final Map<String, dynamic> data;
  List<Map<String, dynamic>> get rates => (data['quotes'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}
