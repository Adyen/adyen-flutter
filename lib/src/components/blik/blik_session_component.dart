import 'package:adyen_checkout/src/components/blik/base_blik_component.dart';
import 'package:adyen_checkout/src/components/session_component_mixin.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';

class BlikSessionComponent extends BaseBlikComponent
    with SessionComponentMixin {
  final SessionDTO session;

  @override
  final String componentId = 'BLIK_SESSION_COMPONENT';

  @override
  String get viewType => Constants.blikComponentSessionKey;

  BlikSessionComponent({
    super.key,
    required super.blikComponentConfiguration,
    required this.session,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    super.adyenLogger,
  });

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.sessionKey: session,
        Constants.blikComponentConfigurationKey: blikComponentConfiguration,
        Constants.paymentMethodKey: paymentMethod,
        Constants.componentIdKey: componentId,
      };
}
