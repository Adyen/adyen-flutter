import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/model/google_pay_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter/material.dart';

class GooglePaySessionComponent extends StatelessWidget {
  const GooglePaySessionComponent({
    super.key,
    required this.componentPlatformApi,
    required this.paymentMethods,
    required this.googlePayComponentConfiguration,
  });

  final ComponentPlatformApi componentPlatformApi;
  final String paymentMethods;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: componentPlatformApi.isInstantPaymentMethodSupportedByPlatform(
        InstantPaymentComponentConfiguration(
            instantPaymentType: InstantPaymentType.googlePay,
            environment: googlePayComponentConfiguration.environment,
            clientKey: googlePayComponentConfiguration.clientKey,
            countryCode: googlePayComponentConfiguration.countryCode,
            amount: googlePayComponentConfiguration.amount.toDTO(),
            analyticsOptionsDTO: googlePayComponentConfiguration
                .analyticsOptions
                .toDTO("0.0.1")),
        paymentMethods,
      ),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data != null) {
          final sdkVersionNumber = snapshot.data ?? "";
          return const Text("SUCCESS");
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
