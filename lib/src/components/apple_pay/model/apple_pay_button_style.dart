import 'apple_pay_button_theme.dart';
import 'apple_pay_button_type.dart';

class ApplePayButtonStyle {
  final ApplePayButtonTheme? theme;
  final ApplePayButtonType? type;
  final double? cornerRadius;

  const ApplePayButtonStyle({
    this.theme,
    this.type,
    this.cornerRadius,
  });
}
