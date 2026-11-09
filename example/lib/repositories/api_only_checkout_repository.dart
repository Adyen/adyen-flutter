import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:flutter/foundation.dart';

/// Backs the API-only (custom card / CSE) screen: it calls the payments
/// endpoint directly and resolves any returned action via the action-only
/// [AdyenCheckout.instance.handleAction].
class ApiOnlyCheckoutRepository {
  final Service service;

  ApiOnlyCheckoutRepository({required this.service});

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
        cardConfiguration: const CardConfiguration(
          showCardholderName: true,
          showStorePaymentMethod: false,
          showSupportedCardBrandLogos: true,
        ),
        googlePayConfiguration: defaultTargetPlatform == TargetPlatform.android
            ? const GooglePayConfiguration(
                googlePayEnvironment: Config.googlePayEnvironment,
                countryCode: Config.countryCode,
                emailRequired: true,
              )
            : null,
        applePayConfiguration: defaultTargetPlatform == TargetPlatform.iOS &&
                Config.merchantId.isNotEmpty
            ? const ApplePayConfiguration(
                merchantId: Config.merchantId,
                merchantName: Config.merchantName,
                amount: Config.amount,
                countryCode: Config.countryCode,
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
      AdyenCheckout.instance.handleAction(
        action: Action.fromJson(actionJson),
        configuration: buildConfiguration(),
        onAdditionalDetails: onAdditionalDetails,
      );
}
