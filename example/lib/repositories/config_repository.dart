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
    final Map<String, dynamic>? launchConfigJson =
        launchConfigString != null ? jsonDecode(launchConfigString) : null;
    final Map<String, dynamic> cardConfigJson =
        launchConfigJson?[cardConfigurationKey] ?? {};
    return CardConfigurationExtension.fromJson(cardConfigJson);
  }

  Future<String?> _loadLaunchConfig() async {
    final configBase64 =
        await flutterLaunchArguments.getString(launchConfigKey);
    print("Raw: $configBase64");

    if (configBase64 == null) {
      return null;
    }

    List<int> bytes = base64.decode(configBase64);
    String jsonString = utf8.decode(bytes);
    print("Config JSON: $jsonString");
    return jsonString;
  }
}
