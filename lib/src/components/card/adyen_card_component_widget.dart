import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_advanced_flow_widget.dart';
import 'package:adyen_checkout/src/components/card/card_session_flow_widget.dart';
import 'package:flutter/foundation.dart';
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
    final double initialHeight = _determineInitialHeight(
        cardComponentSessionFlow.cardComponentConfiguration.cardConfiguration);
    return CardSessionFlowWidget(
      cardComponentConfiguration:
          cardComponentSessionFlow.cardComponentConfiguration,
      sessionResponse: cardComponentSessionFlow.sessionResponse,
      onPaymentResult: onPaymentResult,
      initialHeight: initialHeight,
    );
  }

  CardAdvancedFlowWidget _buildCardAdvancedFlowWidget() {
    final CardComponentAdvancedFlow cardComponentAdvancedFlow =
        componentPaymentFlow as CardComponentAdvancedFlow;
    final double initialHeight = _determineInitialHeight(
        cardComponentAdvancedFlow.cardComponentConfiguration.cardConfiguration);
    return CardAdvancedFlowWidget(
      cardComponentConfiguration:
          cardComponentAdvancedFlow.cardComponentConfiguration,
      paymentMethods: cardComponentAdvancedFlow.paymentMethods,
      onPayments: cardComponentAdvancedFlow.onPayments,
      onPaymentsDetails: cardComponentAdvancedFlow.onPaymentsDetails,
      onPaymentResult: onPaymentResult,
      initialHeight: initialHeight,
    );
  }

  double _determineInitialHeight(CardConfiguration cardConfiguration) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _determineInitialAndroidViewHeight(cardConfiguration);
      case TargetPlatform.iOS:
        return _determineInitialIosViewHeight(cardConfiguration);
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  double _determineInitialAndroidViewHeight(
      CardConfiguration cardConfiguration) {
    if (cardConfiguration.showCvc) {
      return 274;
    } else if (cardConfiguration.holderNameRequired) {
      return 370;
    }

    return 274;
  }

  double _determineInitialIosViewHeight(CardConfiguration cardConfiguration) {
    return 279;
  }
}
