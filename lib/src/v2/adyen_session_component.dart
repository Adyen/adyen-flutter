import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/before_submit.dart';
import 'package:adyen_checkout/src/common/model/checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/v2/adyen_base_component.dart';

class AdyenSessionComponent extends AdyenBaseComponent
    implements SessionCheckoutFlutterInterface {
  final SessionCheckout sessionCheckout;

  @override
  final String componentId = "SESSION_ADYEN_COMPONENT";

  @override
  String get viewType => Constants.adyenSessionComponentKey;

  AdyenSessionComponent({
    super.key,
    required super.checkoutConfiguration,
    required this.sessionCheckout,
    required super.paymentMethod,
    required super.paymentMethodTxVariant,
    required super.onPaymentResult,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.controller,
    super.gestureRecognizers,
    super.adyenLogger,
    super.onBinLookup,
    super.onBinValue,
  }) {
    SessionCheckoutFlutterInterface.setUp(this);
  }

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.sessionKey: sessionCheckout.toDTO(),
        Constants.checkoutConfigurationKey: checkoutConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.paymentMethodTxVariantKey: paymentMethodTxVariant,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };

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

  @override
  Future<BeforeSubmitResultDTO> onBeforeSubmit(BeforeSubmitDataDTO data) async {
    final onBeforeSubmit = sessionCheckout.onBeforeSubmit;
    if (onBeforeSubmit == null) {
      return BeforeSubmitResultDTO(isAborted: false, data: data);
    }

    final BeforeSubmitResult result = await onBeforeSubmit(data.fromDTO());
    return result.toDTO();
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
