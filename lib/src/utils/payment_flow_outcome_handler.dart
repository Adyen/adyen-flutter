import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/payment_flow_outcome.dart';

class PaymentFlowOutcomeHandler {
  PaymentFlowOutcomeDTO mapToPaymentOutcomeDTO(
      PaymentFlowOutcome paymentFlowOutcome) {
    return switch (paymentFlowOutcome) {
      Finished() => PaymentFlowOutcomeDTO(
          paymentFlowResultType: PaymentFlowResultType.finished,
          result: paymentFlowOutcome.resultCode,
        ),
      Action() => PaymentFlowOutcomeDTO(
          paymentFlowResultType: PaymentFlowResultType.action,
          actionResponse: paymentFlowOutcome.actionResponse,
        ),
      Error() => PaymentFlowOutcomeDTO(
          paymentFlowResultType: PaymentFlowResultType.error,
          error: ErrorDTO(
            errorMessage: paymentFlowOutcome.errorMessage,
            reason: paymentFlowOutcome.reason,
            dismissDropIn: paymentFlowOutcome.dismissDropIn,
          ),
        ),
    };
  }
}
