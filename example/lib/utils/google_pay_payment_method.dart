import 'package:collection/collection.dart';

const googlePayPaymentMethodTypes = {'googlepay', 'paywithgoogle'};

bool isGooglePayPaymentMethod(Map<String, dynamic> paymentMethod) =>
    googlePayPaymentMethodTypes.contains(paymentMethod["type"]);

Map<String, dynamic> extractGooglePayPaymentMethod(
  Map<String, dynamic> paymentMethods,
) =>
    switch (paymentMethods["paymentMethods"]) {
      final List list => list
              .whereType<Map<String, dynamic>>()
              .firstWhereOrNull(isGooglePayPaymentMethod) ??
          {},
      _ => {},
    };
