import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/advanced_component_mixin.dart';
import 'package:adyen_checkout/src/components/blik/base_blik_component.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class BlikAdvancedComponent extends BaseBlikComponent
    with AdvancedComponentMixin {
  @override
  final AdvancedCheckout advancedCheckout;
  @override
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = 'BLIK_ADVANCED_COMPONENT';

  @override
  String get viewType => Constants.blikComponentAdvancedKey;

  BlikAdvancedComponent({
    super.key,
    required super.blikComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.initialViewHeight,
    super.adyenLogger,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.paymentMethodKey: paymentMethod,
        Constants.blikComponentConfigurationKey: blikComponentConfiguration,
        Constants.componentIdKey: componentId,
      };
}
