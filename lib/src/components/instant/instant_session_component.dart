import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/instant/base_instant_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class InstantSessionComponent extends BaseInstantComponent {
  final SessionCheckout sessionCheckout;

  InstantSessionComponent({
    required super.componentId,
    required this.sessionCheckout,
  });

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO paymentResultDTO) {
    String resultCode = paymentResultDTO.result?.resultCode ?? "";
    adyenLogger.print("Instant component session result code: $resultCode");
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO.result?.sessionId ?? "",
      sessionData: paymentResultDTO.result?.sessionData ?? "",
      resultCode: resultCode,
    ));
  }
}
