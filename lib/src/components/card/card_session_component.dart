import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/components/card/base_card_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class CardSessionComponent extends BaseCardComponent {
  final SessionDTO session;

  @override
  final String componentId = "CARD_SESSION_COMPONENT";

  @override
  String get viewType => Constants.cardComponentSessionKey;

  CardSessionComponent({
    super.key,
    required super.cardComponentConfiguration,
    required this.session,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.gestureRecognizers,
    super.adyenLogger,
  });

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.sessionKey: session,
        Constants.cardComponentConfigurationKey: cardComponentConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    } else if (event.type case ComponentCommunicationType.resize) {
      onResize(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Card component session flow result code: $resultCode");
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
