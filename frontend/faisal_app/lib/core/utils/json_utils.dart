/// Defensive JSON coercion helpers shared by feature mappers.
double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String asString(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  return value is String ? value : '$value';
}

String? asStringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value is String ? value : '$value';
  return text.isEmpty ? null : text;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

DateTime asDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? asDateOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse('$value')?.toLocal();
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry('$key', item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is List) {
    return value
        .map(asMap)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => '$item').toList(growable: false);
  }
  return const <String>[];
}

Map<String, int> asIntMap(dynamic value) {
  final map = asMap(value);
  return map.map((key, item) => MapEntry(key, asInt(item)));
}
