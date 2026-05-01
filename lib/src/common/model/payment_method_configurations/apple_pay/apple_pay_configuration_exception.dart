import 'package:flutter/services.dart';

class ApplePayConfigurationException implements Exception {
  final String code;
  final String? message;
  final Object? details;

  const ApplePayConfigurationException({
    required this.code,
    this.message,
    this.details,
  });

  factory ApplePayConfigurationException.fromPlatformException(
    PlatformException exception,
  ) {
    return switch (exception.code) {
      ApplePayConfigurationExceptionCodes.missingAmount =>
        ApplePayMissingAmountException(
          message: exception.message,
          details: exception.details,
        ),
      ApplePayConfigurationExceptionCodes.invalidConfiguration =>
        ApplePayInvalidConfigurationException(
          message: exception.message,
          details: exception.details,
        ),
      ApplePayConfigurationExceptionCodes.invalidAmount =>
        ApplePayInvalidAmountException(
          message: exception.message,
          details: exception.details,
        ),
      _ => ApplePayConfigurationException(
          code: exception.code,
          message: exception.message,
          details: exception.details,
        ),
    };
  }

  @override
  String toString() {
    return 'ApplePayConfigurationException('
        'code: $code, '
        'message: $message, '
        'details: $details)';
  }
}

final class ApplePayMissingAmountException
    extends ApplePayConfigurationException {
  const ApplePayMissingAmountException({super.message, super.details})
      : super(code: ApplePayConfigurationExceptionCodes.missingAmount);
}

final class ApplePayInvalidConfigurationException
    extends ApplePayConfigurationException {
  const ApplePayInvalidConfigurationException({super.message, super.details})
      : super(code: ApplePayConfigurationExceptionCodes.invalidConfiguration);
}

final class ApplePayInvalidAmountException
    extends ApplePayConfigurationException {
  const ApplePayInvalidAmountException({super.message, super.details})
      : super(code: ApplePayConfigurationExceptionCodes.invalidAmount);
}

abstract final class ApplePayConfigurationExceptionCodes {
  static const missingAmount = 'apple-pay-missing-amount';
  static const invalidConfiguration = 'apple-pay-invalid-configuration';
  static const invalidAmount = 'apple-pay-invalid-amount';
}
