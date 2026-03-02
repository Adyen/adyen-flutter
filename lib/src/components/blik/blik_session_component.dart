import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/components/blik/base_blik_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class BlikSessionComponent extends BaseBlikComponent {
  final SessionDTO session;

  @override
  final String componentId = 'BLIK_SESSION_COMPONENT';

  @override
  String get viewType => Constants.blikComponentSessionKey;

  BlikSessionComponent({
    super.key,
    required super.blikComponentConfiguration,
    required this.session,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    super.adyenLogger,
  });

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.sessionKey: session,
        Constants.blikComponentConfigurationKey: blikComponentConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.componentIdKey: componentId,
      };

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {}

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print('Blik component session flow result code: $resultCode');
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO?.result?.sessionId ?? '',
      sessionData: paymentResultDTO?.result?.sessionData ?? '',
      sessionResult: paymentResultDTO?.result?.sessionResult ?? '',
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
