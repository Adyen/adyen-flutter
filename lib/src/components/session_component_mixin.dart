import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';
import 'package:adyen_checkout/src/components/platform/base_platform_view_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

mixin SessionComponentMixin on BasePlatformViewComponent {
  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print('Session flow result code: $resultCode');
    _resetSession();
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO?.result?.sessionId ?? '',
      sessionResult: paymentResultDTO?.result?.sessionResult ?? '',
      resultCode: resultCode,
    ));
  }

  void _resetSession() => AdyenCheckout.session.clear();
}
