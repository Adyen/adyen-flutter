import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/advanced_component_mixin.dart';
import 'package:adyen_checkout/src/components/card/base_card_component.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class CardAdvancedComponent extends BaseCardComponent
    with AdvancedComponentMixin {
  @override
  final AdvancedCheckout advancedCheckout;
  @override
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = 'CARD_ADVANCED_COMPONENT';

  @override
  String get viewType => Constants.cardComponentAdvancedKey;

  CardAdvancedComponent({
    super.key,
    required super.cardComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.gestureRecognizers,
    super.adyenLogger,
    super.onBinLookup,
    super.onBinValue,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.paymentMethodKey: paymentMethod,
        Constants.cardComponentConfigurationKey: cardComponentConfiguration,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };
}
