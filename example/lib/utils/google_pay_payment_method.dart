import 'package:collection/collection.dart';

const List<String> googlePayPaymentMethodTypes = ['googlepay', 'paywithgoogle'];

bool isGooglePayPaymentMethod(Map<String, dynamic> paymentMethod) =>
    googlePayPaymentMethodTypes.contains(paymentMethod["type"]);

Map<String, dynamic> extractGooglePayPaymentMethod(
  Map<String, dynamic> paymentMethods,
) {
  if (paymentMethods.isEmpty) {
    return <String, String>{};
  }

  final List paymentMethodList = paymentMethods["paymentMethods"] as List;
  return paymentMethodList.firstWhereOrNull(
          (paymentMethod) => isGooglePayPaymentMethod(paymentMethod)) ??
      <String, String>{};
}
