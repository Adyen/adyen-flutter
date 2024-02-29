import 'package:adyen_checkout/adyen_checkout.dart';

class GooglePayButtonStyle {
  final GooglePayButtonType? type;
  final GooglePayButtonTheme? theme;
  final int? cornerRadius;
  final double? width;
  final double? height;

  GooglePayButtonStyle({
    this.type,
    this.theme,
    this.cornerRadius,
    this.width,
    this.height,
  });
}
