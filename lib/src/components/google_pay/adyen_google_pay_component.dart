import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';

class AdyenGooglePayComponent extends StatelessWidget {
  AdyenGooglePayComponent({
    super.key,
    required this.checkout,
    required this.googlePayComponentConfiguration,
  });

  final Checkout checkout;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final ComponentPlatformApi _componentPlatformApi = ComponentPlatformApi();
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sdkVersionNumberProvider.getSdkVersionNumber(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.data != null) {
          final sdkVersionNumber = snapshot.data ?? "";
          return switch (checkout) {
            SessionCheckout() => _buildGooglePaySessionFlowWidget(
                sdkVersionNumber,
                checkout as SessionCheckout,
              ),
            AdvancedCheckout() => const Text("ADVANCED GOOGLE PAY")
          };
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildGooglePaySessionFlowWidget(
    String sdkVersionNumber,
    SessionCheckout sessionCheckout,
  ) {
    return GooglePaySessionComponent(
      componentPlatformApi: _componentPlatformApi,
      paymentMethods: sessionCheckout.paymentMethodsJson,
      googlePayComponentConfiguration: googlePayComponentConfiguration,
    );
  }
}
