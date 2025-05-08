import 'package:adyen_checkout/adyen_checkout.dart';

class GooglePayButtonStyle {
  final GooglePayButtonType? type;
  final GooglePayButtonTheme? theme;
  final int? cornerRadius;

  GooglePayButtonStyle({
    this.type,
    this.theme,
    this.cornerRadius,
  });

  @override
  String toString() {
    return 'GooglePayButtonStyle('
        'type: $type, '
        'theme: $theme, '
        'cornerRadius: $cornerRadius)';
  }
}
