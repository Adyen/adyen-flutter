import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/model/google_pay_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class GooglePaySessionComponent extends StatefulWidget {
  final String googlePayPaymentMethod;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final void Function(PaymentResult) onPaymentResult;
  final ComponentPlatformApi componentPlatformApi;
  final ComponentFlutterApi componentFlutterApi;
  final GooglePayButtonTheme? theme;
  final GooglePayButtonType? type;
  final int? cornerRadius;
  final double? width;
  final double? height;
  final void Function()? onSetupError;
  final Widget? errorIndicator;
  final Widget? loadingIndicator;
  final AdyenLogger adyenLogger;
  final ValueNotifier<bool> isButtonClickable = ValueNotifier<bool>(true);
  static const String basicGooglePayIsReadyToPay = '''{
  "provider": "google_pay",
  "data": {
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": []
  }}''';

  GooglePaySessionComponent({
    super.key,
    required this.googlePayPaymentMethod,
    required this.googlePayComponentConfiguration,
    required this.onPaymentResult,
    required this.componentPlatformApi,
    required this.componentFlutterApi,
    this.theme,
    this.type,
    this.cornerRadius,
    this.width,
    this.height,
    this.onSetupError,
    this.errorIndicator,
    this.loadingIndicator,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  @override
  State<GooglePaySessionComponent> createState() =>
      _GooglePaySessionComponentState();
}

class _GooglePaySessionComponentState extends State<GooglePaySessionComponent> {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();

  @override
  void initState() {
    widget.componentFlutterApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen(_handleComponentCommunication);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isGooglePaySupported(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: ValueListenableBuilder(
                valueListenable: widget.isButtonClickable,
                builder: (BuildContext context, value, Widget? child) {
                  return IgnorePointer(
                    ignoring: value == false,
                    child: RawGooglePayButton(
                      paymentConfiguration: PaymentConfiguration.fromJsonString(
                        GooglePaySessionComponent.basicGooglePayIsReadyToPay,
                      ),
                      onPressed: onPressed,
                      cornerRadius: widget.cornerRadius ??
                          RawGooglePayButton.defaultButtonHeight ~/ 2,
                      theme: widget.theme ?? GooglePayButtonTheme.dark,
                      type: widget.type ?? GooglePayButtonType.buy,
                    ),
                  );
                },
              ),
            );
          } else {
            widget.onSetupError?.call();
            return widget.errorIndicator ?? const SizedBox.shrink();
          }
        }

        return widget.loadingIndicator ?? const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    widget.componentFlutterApi.componentCommunicationStream.close();

    super.dispose();
  }

  void onPressed() {
    widget.isButtonClickable.value = false;
    widget.componentPlatformApi
        .onInstantPaymentMethodPressed(InstantPaymentType.googlePay);
  }

  Future<bool> _isGooglePaySupported() async {
    final String versionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentComponentConfigurationDTO
        instantPaymentComponentConfigurationDTO = widget
            .googlePayComponentConfiguration
            .toInstantPaymentComponentConfigurationDTO(versionNumber);
    return await widget.componentPlatformApi
        .isInstantPaymentMethodSupportedByPlatform(
      instantPaymentComponentConfigurationDTO,
      widget.googlePayPaymentMethod,
    );
  }

  void _handleComponentCommunication(event) async {
    widget.isButtonClickable.value = true;
    if (event.type case ComponentCommunicationType.result) {
      _onResult(event);
    } else if (event.type case ComponentCommunicationType.error) {
      _onError(event);
    }
  }

  void _onResult(ComponentCommunicationModel event) {
    String resultCode = event.paymentResult?.resultCode ?? "";
    widget.adyenLogger
        .print("Google pay session flow result code: $resultCode");
    widget.onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }
}
