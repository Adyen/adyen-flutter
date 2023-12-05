import 'package:adyen_checkout/src/utils/constants.dart';
// import 'package:flutter/services.dart';

class SdkVersionNumberProvider {
  String getSdkVersionNumber() {
    return Constants.versionNumber;
  }

// Future<String> getSdkVersionNumberFromPubspec() async {
//   // requires pubspec provided via asset
//   // assets:
//   //  - pubspec.yaml
//
//   final pubspecContent =
//       await rootBundle.loadString("packages/adyen_checkout/pubspec.yaml");
//   final RegExp regex = RegExp('version:s*(.*?)s*\\n');
//   final match = regex.firstMatch(pubspecContent);
//   final versionNumber = match?.group(1) ?? "";
//   return versionNumber;
// }
}
