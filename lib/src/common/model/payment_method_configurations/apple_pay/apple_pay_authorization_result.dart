import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_payment_error.dart';

sealed class ApplePayAuthorizationResult {
  const ApplePayAuthorizationResult();

  const factory ApplePayAuthorizationResult.success() =
      ApplePayAuthorizationSuccess;

  const factory ApplePayAuthorizationResult.failure({
    required List<ApplePayPaymentError> errors,
  }) = ApplePayAuthorizationFailure;
}

class ApplePayAuthorizationSuccess extends ApplePayAuthorizationResult {
  const ApplePayAuthorizationSuccess();
}

class ApplePayAuthorizationFailure extends ApplePayAuthorizationResult {
  final List<ApplePayPaymentError> errors;

  const ApplePayAuthorizationFailure({
    required this.errors,
  });
}
