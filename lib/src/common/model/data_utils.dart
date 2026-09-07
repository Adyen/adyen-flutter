import 'dart:collection';

Map<String, dynamic> immutableMap(Map<String, dynamic> source) {
  return UnmodifiableMapView<String, dynamic>(
    source.map((key, value) => MapEntry(key, freezeValue(value))),
  );
}

Object? freezeValue(Object? value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('JSON object keys must be strings.');
      }
      result[entry.key as String] = freezeValue(entry.value);
    }
    return immutableMap(result);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(freezeValue));
  }
  return value;
}

Map<String, dynamic> requireMap(Object? value, String name) {
  if (value is! Map) {
    throw FormatException('$name must be a JSON object.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$name contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String requireString(Object? value, String name) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$name must be a non-empty string.');
  }
  return value;
}
