import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/apple_pay/base_apple_pay_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';

class ApplePaySessionComponent extends BaseApplePayComponent {
  @override
  final String componentId = "Apple_PAY_SESSION_COMPONENT";

  ApplePaySessionComponent({
    super.key,
    required super.applePayPaymentMethod,
    required super.applePayComponentConfiguration,
    required super.onPaymentResult,
    required super.style,
    required super.type,
    required super.width,
    required super.height,
    super.cornerRadius,
    super.loadingIndicator,
    super.onUnavailable,
    super.unavailableWidget,
    AdyenLogger? adyenLogger,
  });

  @override
  void handleComponentCommunication(event) {
    isButtonClickable.value = true;
    if (event.type case ComponentCommunicationType.result) {
      _onResult(event);
    } else if (event.type case ComponentCommunicationType.error) {
      _onError(event);
    } else if (event.type case ComponentCommunicationType.loading) {
      _onLoading();
    }
  }

  void _onLoading() => isLoading.value = true;

  void _onResult(ComponentCommunicationModel event) {
    isLoading.value = false;
    String resultCode = event.paymentResult?.resultCode ?? "";
    adyenLogger.print("Apple pay session flow result code: $resultCode");
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    isLoading.value = false;
    String errorMessage = event.data as String;
    onPaymentResult(PaymentError(reason: errorMessage));
  }
}
