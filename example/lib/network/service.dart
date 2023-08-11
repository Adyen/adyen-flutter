import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:http/http.dart' as http;

class Service {
  static const String baseUrl = "checkout-test.adyen.com";
  static const String apiVersion = "v70";
  static const String sessions = "sessions";

  Future<SessionResponseNetworkModel> createSession(
      SessionRequestNetworkModel sessionRequestNetworkModel) async {
    if (Config.xApiKey.isEmpty) {
      throw AssertionError('X_API_KEY is not set in secrets.json');
    }

    final url = Uri.https(baseUrl, "/$apiVersion/$sessions");
    final response = await http.post(
      url,
      headers: {
        "content-type": "application/json",
        "x-API-key": Config.xApiKey,
      },
      body: sessionRequestNetworkModel.toRawJson(),
    );
    return SessionResponseNetworkModel.fromRawJson(response.body);
  }
}
