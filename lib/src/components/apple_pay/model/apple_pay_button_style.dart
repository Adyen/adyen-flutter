import 'package:adyen_checkout/src/components/apple_pay/model/apple_pay_button_theme.dart';
import 'package:adyen_checkout/src/components/apple_pay/model/apple_pay_button_type.dart';

class ApplePayButtonStyle {
  final ApplePayButtonTheme? theme;
  final ApplePayButtonType? type;
  final double? cornerRadius;

  ApplePayButtonStyle({
    this.theme,
    this.type,
    this.cornerRadius,
  });
}
