import 'package:adyen_checkout/src/common/model/payment_method_configurations/three_ds2/adyen_3ds_theme.dart';

final class ThreeDS2Configuration {
  final String? requestorAppURL;
  final String? headingTitle;
  final Adyen3DSTheme? theme;

  ThreeDS2Configuration({
    this.requestorAppURL,
    this.headingTitle,
    this.theme,
  });

  @override
  String toString() {
    return 'ThreeDS2Configuration(requestorAppURL: $requestorAppURL, headingTitle: $headingTitle, theme: $theme,)';
  }
}
