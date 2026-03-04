import 'package:adyen_checkout/src/components/card/base_card_component.dart';
import 'package:adyen_checkout/src/components/session_component_mixin.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';

class CardSessionComponent extends BaseCardComponent with SessionComponentMixin {
  final SessionDTO session;

  @override
  final String componentId = 'CARD_SESSION_COMPONENT';

  @override
  String get viewType => Constants.cardComponentSessionKey;

  CardSessionComponent({
    super.key,
    required super.cardComponentConfiguration,
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
        Constants.cardComponentConfigurationKey: cardComponentConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };
}
