import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/v2/adyen_base_component.dart';

class AdyenSessionComponent extends AdyenBaseComponent {
  final SessionDTO session;

  @override
  final String componentId = "SESSION_ADYEN_COMPONENT";

  @override
  String get viewType => Constants.adyenSessionComponentKey;

  AdyenSessionComponent({
    super.key,
    required super.checkoutConfiguration,
    required this.session,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.gestureRecognizers,
    super.adyenLogger,
    super.onBinLookup,
    super.onBinValue,
  });

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.sessionKey: session,
        Constants.checkoutConfigurationKey: checkoutConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {}

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Adyen component session result code: $resultCode");
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO?.result?.sessionId ?? "",
      sessionResult: paymentResultDTO?.result?.sessionResult ?? "",
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
