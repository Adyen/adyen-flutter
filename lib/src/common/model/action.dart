import 'data_utils.dart';

class Action {
  final String type;
  final String? paymentData;
  final String? paymentMethodType;
  final Map<String, dynamic> data;

  Action({
    required this.type,
    this.paymentData,
    this.paymentMethodType,
    Map<String, dynamic>? data,
  }) : data = immutableMap({
          ...?data,
          'type': type,
          if (paymentData != null) 'paymentData': paymentData,
          if (paymentMethodType != null) 'paymentMethodType': paymentMethodType,
        });

  factory Action.fromJson(Map<String, dynamic> json) {
    final source = Map<String, dynamic>.from(json);
    return Action(
      type: requireString(source['type'], 'Action.type'),
      paymentData: source['paymentData'] as String?,
      paymentMethodType: source['paymentMethodType'] as String?,
      data: source,
    );
  }

  @override
  String toString() => 'Action(type: $type)';
}
