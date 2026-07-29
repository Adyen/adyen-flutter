import 'package:adyen_checkout/src/components/apple_pay/model/apple_pay_button_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Renders a native iOS `PKPaymentButton` as a platform view.
///
/// Apple Pay's native SDK component has no embeddable inline view of its
/// own (its only UI is the full-screen payment sheet), so unlike
/// Card/Blik/Google Pay this button is a bespoke, minimal native view - it's
/// only a visible trigger. Tapping it is reported back over
/// [ComponentCommunicationType.buttonPressed] and handled the same way the
/// button already was before (triggering the existing
/// `ComponentPlatformApi.onInstantPaymentPressed` flow).
class ApplePayButtonPlatformView extends StatelessWidget {
  static const String viewType = 'ApplePayButtonView';

  final String componentId;
  final ApplePayButtonStyle? style;

  const ApplePayButtonPlatformView({
    super.key,
    required this.componentId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = {
      'componentId': componentId,
      if (style?.type != null) 'type': style!.type!.name,
      if (style?.theme != null) 'theme': style!.theme!.name,
      if (style?.cornerRadius != null) 'cornerRadius': style!.cornerRadius,
    };

    return UiKitView(
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
