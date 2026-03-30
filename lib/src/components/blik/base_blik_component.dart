import 'package:adyen_checkout/src/components/platform/base_platform_view_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

abstract class BaseBlikComponent extends BasePlatformViewComponent {
  final BlikComponentConfigurationDTO blikComponentConfiguration;

  BaseBlikComponent({
    super.key,
    required this.blikComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    super.adyenLogger,
  });
}
