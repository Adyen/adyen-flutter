import 'package:adyen_checkout/src/common/models/payment_outcome.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class PaymentOutcomeHandler {
  PaymentOutcomeDTO mapToPaymentOutcomeDTO(
      PaymentOutcome paymentFlowOutcome) {
    return switch (paymentFlowOutcome) {
      Finished() => PaymentOutcomeDTO(
        paymentOutcomeType: PaymentOutcomeType.finished,
          result: paymentFlowOutcome.resultCode,
        ),
      Action() => PaymentOutcomeDTO(
        paymentOutcomeType: PaymentOutcomeType.action,
          actionResponse: paymentFlowOutcome.actionResponse,
        ),
      Error() => PaymentOutcomeDTO(
          paymentOutcomeType: PaymentOutcomeType.error,
          error: ErrorDTO(
            errorMessage: paymentFlowOutcome.errorMessage,
            reason: paymentFlowOutcome.reason,
            dismissDropIn: paymentFlowOutcome.dismissDropIn,
          ),
        ),
    };
  }
}
