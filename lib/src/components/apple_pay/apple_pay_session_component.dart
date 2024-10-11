import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/apple_pay/base_apple_pay_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class ApplePaySessionComponent extends BaseApplePayComponent {
  final SessionDTO session;

  @override
  final String componentId = "APPLE_PAY_SESSION_COMPONENT";

  ApplePaySessionComponent({
    super.key,
    required this.session,
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
      onResult(event);
    } else if (event.type case ComponentCommunicationType.loading) {
      onLoading();
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Apple Pay session flow result code: $resultCode");
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO?.result?.sessionId ?? "",
      sessionData: paymentResultDTO?.result?.sessionData ?? "",
      sessionResult: paymentResultDTO?.result?.sessionResult ?? "",
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
