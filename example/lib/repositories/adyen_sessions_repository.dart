import 'dart:io';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/network/service.dart';

class AdyenSessionsRepository {
  final Service service = Service();

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<SessionModel> createSession(Amount amount) async {
    SessionRequestNetworkModel sessionRequestNetworkModel =
        SessionRequestNetworkModel(
      merchantAccount: Config.merchantAccount,
      amount: AmountNetworkModel(
        currency: amount.currency,
        value: amount.value,
      ),
      returnUrl: determineExampleReturnUrl(),
      reference: Config.shopperReference,
      countryCode: Config.countryCode,
    );

    SessionResponseNetworkModel sessionResponseNetworkModel =
        await service.createSession(sessionRequestNetworkModel);

    return SessionModel(
      id: sessionResponseNetworkModel.id,
      sessionData: sessionResponseNetworkModel.sessionData,
    );
  }

  String determineExampleReturnUrl() {
    if (Platform.isAndroid) {
      return "adyencheckout://com.adyen.adyen_checkout_example";
    } else if (Platform.isIOS) {
      return "ui-host://payments";
    } else {
      throw Exception("Unsupported platform");
    }
  }
}
