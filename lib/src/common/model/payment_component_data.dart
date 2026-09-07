import 'data_utils.dart';

class PaymentComponentData {
  final Map<String, dynamic> data;

  PaymentComponentData({required Map<String, dynamic> data})
      : data = immutableMap(data);

  factory PaymentComponentData.fromJson(Map<String, dynamic> json) =>
      PaymentComponentData(data: json);

  Map<String, dynamic>? get paymentMethod =>
      _optionalMap(data['paymentMethod']);

  bool? get storePaymentMethod => data['storePaymentMethod'] as bool?;

  @override
  String toString() => 'PaymentComponentData(fields: ${data.keys.toList()})';
}

Map<String, dynamic>? _optionalMap(Object? value) {
  if (value == null) return null;
  return immutableMap(requireMap(value, 'data'));
}
