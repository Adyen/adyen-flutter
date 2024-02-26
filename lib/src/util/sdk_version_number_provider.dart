import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:flutter/services.dart';

class SdkVersionNumberProvider {
  static SdkVersionNumberProvider? _instance;

  SdkVersionNumberProvider._init();

  static SdkVersionNumberProvider get instance =>
      _instance ??= SdkVersionNumberProvider._init();

  Future<String> getSdkVersionNumber() async {
    try {
      final pubspecContent =
          await rootBundle.loadString("packages/adyen_checkout/pubspec.yaml");
      final RegExp regex = RegExp('version:s*(.*?)s*\\n');
      final match = regex.firstMatch(pubspecContent);
      final versionNumber = match?.group(1) ?? "";
      return versionNumber.trim();
    } catch (exception) {
      AdyenLogger.instance.print(
          "Could not find adyen checkout pubspec file for reading the SDK version number");
      return "";
    }
  }
}
