import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:collection/collection.dart';

/// Payment method types demoed by the V2 (v6 generic component) screens.
enum V2PaymentMethodType {
  card('scheme'),
  blik('blik'),
  googlePay('googlepay');

  const V2PaymentMethodType(this.txVariant);

  final String txVariant;
}

/// Builds the [CheckoutConfiguration] for the V2 demo screens, attaching only
/// the payment-method-specific configuration that matches [paymentMethodType].
CheckoutConfiguration buildV2CheckoutConfiguration(
  V2PaymentMethodType paymentMethodType,
) {
  return CheckoutConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    shopperLocale: Config.shopperLocale,
    amount: Config.amount,
    cardConfiguration: switch (paymentMethodType) {
      V2PaymentMethodType.card => const CardConfiguration(),
      _ => null,
    },
    googlePayConfiguration: switch (paymentMethodType) {
      V2PaymentMethodType.googlePay => const GooglePayConfiguration(
          googlePayEnvironment: Config.googlePayEnvironment),
      _ => null,
    },
  );
}

/// Extracts the payment method matching [paymentMethodType] from the raw
/// `paymentMethods` response, or an empty map if it isn't present.
Map<String, dynamic> extractV2PaymentMethod(
  Map<String, dynamic> paymentMethods,
  V2PaymentMethodType paymentMethodType,
) {
  final paymentMethodList = paymentMethods['paymentMethods'] as List? ?? [];
  return paymentMethodList.firstWhereOrNull(
        (paymentMethod) => paymentMethod['type'] == paymentMethodType.txVariant,
      ) as Map<String, dynamic>? ??
      <String, dynamic>{};
}
