import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:http/http.dart' as http;

class Service {
  Future<SessionResponseNetworkModel> createSession(
      SessionRequestNetworkModel sessionRequestNetworkModel,
      Environment environment) async {
    final url = Uri.https(Config.baseUrl, "/${Config.apiVersion}/sessions");
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
