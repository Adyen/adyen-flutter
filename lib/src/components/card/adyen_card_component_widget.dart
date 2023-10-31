import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_advanced_flow_widget.dart';
import 'package:adyen_checkout/src/components/card/card_session_flow_widget.dart';
import 'package:flutter/widgets.dart';

class AdyenCardComponentWidget extends StatelessWidget {
  final ComponentPaymentFlow componentPaymentFlow;
  final Future<void> Function(PaymentResult) onPaymentResult;

  const AdyenCardComponentWidget({
    super.key,
    required this.componentPaymentFlow,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context) {
    return switch (componentPaymentFlow) {
      CardComponentSessionFlow() => _buildCardSessionFlowWidget(),
      CardComponentAdvancedFlow() => _buildCardAdvancedFlowWidget()
    };
  }

  CardSessionFlowWidget _buildCardSessionFlowWidget() {
    final CardComponentSessionFlow cardComponentSessionFlow =
        componentPaymentFlow as CardComponentSessionFlow;
    return CardSessionFlowWidget(
      cardComponentConfiguration:
          cardComponentSessionFlow.cardComponentConfiguration,
      session: cardComponentSessionFlow.session,
      onPaymentResult: onPaymentResult,
    );
  }

  CardAdvancedFlowWidget _buildCardAdvancedFlowWidget() {
    final CardComponentAdvancedFlow cardComponentAdvancedFlow =
        componentPaymentFlow as CardComponentAdvancedFlow;
    return CardAdvancedFlowWidget(
      cardComponentConfiguration:
          cardComponentAdvancedFlow.cardComponentConfiguration,
      paymentMethods: cardComponentAdvancedFlow.paymentMethods,
      onPayments: cardComponentAdvancedFlow.onPayments,
      onPaymentsDetails: cardComponentAdvancedFlow.onPaymentsDetails,
      onPaymentResult: onPaymentResult,
    );
  }
}
