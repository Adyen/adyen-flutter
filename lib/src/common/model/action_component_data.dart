import 'data_utils.dart';

class ActionComponentData {
  final Map<String, dynamic> data;

  ActionComponentData({required Map<String, dynamic> data})
      : data = immutableMap(data);

  factory ActionComponentData.fromJson(Map<String, dynamic> json) =>
      ActionComponentData(data: json);

  String? get paymentData => data['paymentData'] as String?;

  Map<String, dynamic>? get details {
    final value = data['details'];
    if (value == null) return null;
    return immutableMap(requireMap(value, 'ActionComponentData.details'));
  }

  @override
  String toString() => 'ActionComponentData(fields: ${data.keys.toList()})';
}
