import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/model/google_pay_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class GooglePaySessionComponent extends StatelessWidget {
  GooglePaySessionComponent({
    super.key,
    required this.componentPlatformApi,
    required this.googlePayPaymentMethod,
    required this.googlePayComponentConfiguration,
  });

  final ComponentPlatformApi componentPlatformApi;
  final String googlePayPaymentMethod;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isGooglePaySupported(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data == true) {
          return RawGooglePayButton(
            paymentConfiguration:
                PaymentConfiguration.fromJsonString(basicGooglePayIsReadyToPay),
            onPressed: onPressed,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void onPressed() {
    componentPlatformApi
        .onInstantPaymentMethodPressed(InstantPaymentType.googlePay);
  }

  Future<bool> _isGooglePaySupported() async {
    final String versionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentComponentConfigurationDTO
        instantPaymentComponentConfigurationDTO =
        googlePayComponentConfiguration
            .toInstantPaymentComponentConfigurationDTO(versionNumber);
    return await componentPlatformApi.isInstantPaymentMethodSupportedByPlatform(
      instantPaymentComponentConfigurationDTO,
      googlePayPaymentMethod,
    );
  }

  static const String basicGooglePayIsReadyToPay = '''{
  "provider": "google_pay",
  "data": {
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": []
  }
}''';
}
