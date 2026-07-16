import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/extensions/card_configuration_extension.dart';
import 'package:flutter_launch_arguments/flutter_launch_arguments.dart';

class ConfigRepository {
  final String launchConfigKey = "config";
  final String cardConfigurationKey = "CARD_CONFIGURATION";
  final FlutterLaunchArguments flutterLaunchArguments =
      FlutterLaunchArguments();

  Future<CardConfiguration> loadCardConfiguration() async {
    final String? launchConfigString = await _loadLaunchConfig();
    if (launchConfigString == null) {
      return const CardConfiguration();
    }

    try {
      final launchConfigJson = jsonDecode(launchConfigString);
      if (launchConfigJson is! Map<String, dynamic>) {
        return const CardConfiguration();
      }

      final cardConfigJson = launchConfigJson[cardConfigurationKey];
      return CardConfigurationExtension.fromJson(
        cardConfigJson is Map<String, dynamic> ? cardConfigJson : {},
      );
    } on FormatException {
      return const CardConfiguration();
    }
  }

  Future<String?> _loadLaunchConfig() async {
    try {
      final configBase64 =
          await flutterLaunchArguments.getString(launchConfigKey);
      if (configBase64 == null) {
        return null;
      }

      return utf8.decode(base64.decode(configBase64.trim()));
    } on FormatException {
      return null;
    }
  }
}
