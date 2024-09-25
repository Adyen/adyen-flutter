import 'package:adyen_checkout/src/common/model/payment_event.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class PaymentEventHandler {
  PaymentEventDTO mapToPaymentEventDTO(PaymentEvent paymentEvent) {
    return switch (paymentEvent) {
      Finished() => PaymentEventDTO(
          paymentEventType: PaymentEventType.finished,
          result: paymentEvent.resultCode,
        ),
      Action() => PaymentEventDTO(
          paymentEventType: PaymentEventType.action,
          data: paymentEvent.actionResponse,
        ),
      Error() => PaymentEventDTO(
          paymentEventType: PaymentEventType.error,
          error: ErrorDTO(
            errorMessage: paymentEvent.errorMessage,
            reason: paymentEvent.reason,
            dismissDropIn: paymentEvent.dismissDropIn,
          ),
        ),
      Update() => PaymentEventDTO(
          paymentEventType: PaymentEventType.update,
          data: {
            "updatedPaymentMethods": paymentEvent.paymentMethods,
            "orderResponse": paymentEvent.orderResponse,
          },
        ),
    };
  }
}
