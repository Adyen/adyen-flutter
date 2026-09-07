class CheckoutError implements Exception {
  static const String genericCode = 'Generic';
  static const String callbackFailureCode = 'CallbackFailure';
  static const String cancellationCode = 'Cancelled';
  static const String invalidConfigurationCode = 'InvalidConfiguration';
  static const String paymentMethodFailureCode = 'PaymentMethodFailure';
  static const String alreadyActiveCode = 'CheckoutAlreadyActive';
  static const String missingControllerCode = 'MissingController';

  final String code;
  final String? message;
  final Object? cause;

  const CheckoutError({
    required this.code,
    this.message,
    this.cause,
  });

  CheckoutError.callbackFailure({String? message, Object? cause})
      : this(
          code: callbackFailureCode,
          message: message ?? 'A checkout callback failed.',
          cause: cause,
        );

  CheckoutError.alreadyActive()
      : this(
          code: alreadyActiveCode,
          message: 'Another checkout flow is already active.',
        );

  CheckoutError.missingController()
      : this(
          code: missingControllerCode,
          message: 'A CheckoutController is required for this payment method.',
        );

  @override
  String toString() => message == null
      ? 'CheckoutError($code)'
      : 'CheckoutError($code): $message';
}
