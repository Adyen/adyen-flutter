import 'data_utils.dart';
import 'payment_method.dart';
import 'stored_payment_method.dart';

class PaymentMethods {
  final List<PaymentMethod> regular;
  final List<StoredPaymentMethod> stored;

  PaymentMethods({
    List<PaymentMethod>? regular,
    List<StoredPaymentMethod>? stored,
    List<PaymentMethod>? paymentMethods,
    List<StoredPaymentMethod>? storedPaymentMethods,
  })  : regular = List<PaymentMethod>.unmodifiable(
          regular ?? paymentMethods ?? const [],
        ),
        stored = List<StoredPaymentMethod>.unmodifiable(
          stored ?? storedPaymentMethods ?? const [],
        );

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    final regularJson = json['paymentMethods'];
    final storedJson = json['storedPaymentMethods'];
    return PaymentMethods(
      regular: _decodeRegular(regularJson),
      stored: _decodeStored(storedJson),
    );
  }

  List<PaymentMethod> get paymentMethods => regular;

  List<StoredPaymentMethod> get storedPaymentMethods => stored;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'paymentMethods': regular.map((method) => method.data).toList(),
        'storedPaymentMethods': stored.map((method) => method.data).toList(),
      };

  @override
  String toString() =>
      'PaymentMethods(regular: ${regular.length}, stored: ${stored.length})';
}

List<PaymentMethod> _decodeRegular(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException(
        'PaymentMethods.paymentMethods must be a list.');
  }
  return value
      .map((item) => PaymentMethod.fromJson(requireMap(item, 'paymentMethod')))
      .toList();
}

List<StoredPaymentMethod> _decodeStored(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException(
      'PaymentMethods.storedPaymentMethods must be a list.',
    );
  }
  return value
      .map((item) => StoredPaymentMethod.fromJson(
            requireMap(item, 'storedPaymentMethod'),
          ))
      .toList();
}
