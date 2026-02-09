import 'package:adyen_checkout/src/common/model/payment_method_configurations/three_ds2/adyen_3ds_theme.dart';

final class ThreeDS2Configuration {
  final String? requestorAppURL;
  final Adyen3DSTheme? theme;
  final String? toolbarTitle;

  ThreeDS2Configuration({
    this.requestorAppURL,
    this.theme,
    this.toolbarTitle,
  });

  @override
  String toString() {
    return 'ThreeDS2Configuration(requestorAppURL: $requestorAppURL, theme: $theme, toolbarTitle: $toolbarTitle)';
  }
}
