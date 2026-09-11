import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:flutter/foundation.dart';

class AdvancedCheckoutRepository {
  final Service service;

  AdvancedCheckoutRepository({required this.service});

  String get channel =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';

  String determineReturnUrl({TargetPlatform? platform}) {
    if ((platform ?? defaultTargetPlatform) == TargetPlatform.android) {
      return Config.androidReturnUrl;
    }
    return Config.iosReturnUrl;
  }

  CheckoutConfiguration buildConfiguration() => CheckoutConfiguration(
        environment: Config.environment,
        clientKey: Config.clientKey,
        amount: Config.amount,
        countryCode: Config.countryCode,
        cardConfiguration: const CardConfiguration(
          showCardholderName: true,
          showStorePaymentMethod: false,
          showSupportedCardBrandLogos: true,
        ),
        googlePayConfiguration: defaultTargetPlatform == TargetPlatform.android
            ? const GooglePayConfiguration(
                googlePayEnvironment: Config.googlePayEnvironment,
                emailRequired: true,
              )
            : null,
        applePayConfiguration: defaultTargetPlatform == TargetPlatform.iOS &&
                Config.merchantId.isNotEmpty
            ? const ApplePayConfiguration(
                merchantId: Config.merchantId,
                merchantName: Config.merchantName,
                applePaySummaryItems: [
                  ApplePaySummaryItem(
                    label: Config.merchantName,
                    amount: Config.amount,
                    type: ApplePaySummaryItemType.definite,
                  ),
                ],
                buttonStyle: ApplePayButtonStyle(type: ApplePayButtonType.buy),
                buttonWidth: 200,
                buttonHeight: 48,
              )
            : null,
      );

  Future<PaymentMethods> fetchPaymentMethods() async {
    final response = await service.fetchPaymentMethods({
      'merchantAccount': Config.merchantAccount,
      'amount': Config.amount.toJson(),
      'countryCode': Config.countryCode,
      'channel': channel,
    });
    return PaymentMethods.fromJson(response);
  }

  Future<AdvancedCheckout> setupCheckout({
    required AdvancedCheckoutCallbacks callbacks,
  }) async {
    final paymentMethods = await fetchPaymentMethods();
    return Checkout.instance.setupAdvanced(
      paymentMethods: paymentMethods,
      configuration: buildConfiguration(),
      callbacks: callbacks,
    );
  }

  Future<SubmitResult> onSubmit(PaymentComponentData data) async {
    final response = await service.postPayments({
      'merchantAccount': Config.merchantAccount,
      'shopperReference': Config.shopperReference,
      'reference': 'flutter-test_${DateTime.now().millisecondsSinceEpoch}',
      'returnUrl': determineReturnUrl(),
      'amount': Config.amount.toJson(),
      'countryCode': Config.countryCode,
      'channel': channel,
      'recurringProcessingModel': 'CardOnFile',
      'shopperInteraction': 'Ecommerce',
      'authenticationData': {
        'threeDSRequestData': {
          'nativeThreeDS': 'preferred',
        },
      },
      ...data.data,
      'lineItems': Config.lineItems,
    });
    final action = response['action'];
    if (action is Map) {
      return SubmitResult.action(
        Action.fromJson(Map<String, dynamic>.from(action)),
      );
    }
    return SubmitResult.completion(
      resultCode: response['resultCode'] as String? ?? 'Error',
    );
  }

  Future<AdditionalDetailsResult> onAdditionalDetails(
    ActionComponentData data,
  ) async {
    final response = await service.postPaymentsDetails(data.data);
    return AdditionalDetailsResult.completion(
      resultCode: response['resultCode'] as String? ?? 'Error',
    );
  }

  Future<AdvancedCheckoutResult> handleAction({
    required Map<String, dynamic> actionJson,
    required Future<AdditionalDetailsResult> Function(ActionComponentData data)
        onAdditionalDetails,
  }) =>
      Checkout.instance.handleAction(
        action: Action.fromJson(actionJson),
        configuration: buildConfiguration(),
        onAdditionalDetails: onAdditionalDetails,
      );
}
