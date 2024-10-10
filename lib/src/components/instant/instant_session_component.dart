import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/instant/base_instant_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class InstantSessionComponent extends BaseInstantComponent {
  final SessionCheckout sessionCheckout;

  @override
  final String componentId = "INSTANT_SESSION_COMPONENT";

  InstantSessionComponent({required this.sessionCheckout});

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Instant component session result code: $resultCode");
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO.result?.sessionId ?? "",
      sessionData: paymentResultDTO.result?.sessionData ?? "",
      sessionResult: paymentResultDTO.result?.sessionResult,
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
