import 'package:flutter/services.dart';

class SdkVersionNumberProvider {
  Future<String> getSdkVersionNumber() async {
    try {
      final pubspecContent =
          await rootBundle.loadString("packages/adyen_checkout/pubspec.yaml");
      final RegExp regex = RegExp('version:s*(.*?)s*\\n');
      final match = regex.firstMatch(pubspecContent);
      final versionNumber = match?.group(1) ?? "";
      return versionNumber;
    } catch (exception) {
      return "";
    }
  }
}
