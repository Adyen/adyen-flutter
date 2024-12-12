import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/components/google_pay/base_google_pay_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class GooglePaySessionComponent extends BaseGooglePayComponent {
  final SessionDTO session;

  @override
  final String componentId = "GOOGLE_PAY_SESSION_COMPONENT";

  GooglePaySessionComponent({
    super.key,
    required this.session,
    required super.googlePayPaymentMethod,
    required super.googlePayComponentConfiguration,
    required super.onPaymentResult,
    required super.theme,
    required super.type,
    required super.cornerRadius,
    required super.width,
    required super.height,
    super.loadingIndicator,
    super.onUnavailable,
    super.unavailableWidget,
    super.adyenLogger,
  });

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    isButtonClickable.value = true;
    if (event.type case ComponentCommunicationType.loading) {
      onLoading();
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Google Pay session result code: $resultCode");
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO.result?.sessionId ?? "",
      sessionData: paymentResultDTO.result?.sessionData ?? "",
      sessionResult: paymentResultDTO.result?.sessionResult ?? "",
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
