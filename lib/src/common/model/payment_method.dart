import 'data_utils.dart';

class PaymentMethod {
  final String type;
  final String name;
  final Map<String, dynamic> data;

  PaymentMethod({
    required this.type,
    required this.name,
    Map<String, dynamic>? data,
  }) : data = immutableMap({
          ...?data,
          'type': type,
          'name': name,
        });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final source = Map<String, dynamic>.from(json);
    return PaymentMethod(
      type: requireString(source['type'], 'PaymentMethod.type'),
      name: requireString(source['name'], 'PaymentMethod.name'),
      data: source,
    );
  }

  @override
  String toString() => 'PaymentMethod(type: $type, name: $name)';
}
