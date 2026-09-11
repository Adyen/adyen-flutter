import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:collection/collection.dart';

const instantPaymentMethodTypes = [
  'ideal',
  'paypal',
  'klarna',
  'paybybank',
  'twint',
];

List<PaymentMethod> resolveInstantPaymentMethods(
  List<PaymentMethod> paymentMethods,
) =>
    instantPaymentMethodTypes
        .map(
          (type) => paymentMethods
              .firstWhereOrNull((paymentMethod) => paymentMethod.type == type),
        )
        .whereType<PaymentMethod>()
        .toList();
