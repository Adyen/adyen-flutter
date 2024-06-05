import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenCseRepository extends AdyenBaseRepository {
  AdyenCseRepository({required super.service});

  Future<Map<String, dynamic>> makePayment(EncryptedCard encryptedCard) async {
    Map<String, dynamic> requestBody = await _createRequestBody(encryptedCard);
    return await service.postPayments(requestBody);
  }

  Future<Map<String, dynamic>> _createRequestBody(
      EncryptedCard encryptedCard) async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";

    return {
      "amount": {"currency": "EUR", "value": 120000},
      "reference": "flutter-test_${DateTime.now().millisecondsSinceEpoch}",
      "paymentMethod": {
        "type": "scheme",
        "encryptedCardNumber": "${encryptedCard.encryptedCardNumber}",
        "encryptedExpiryMonth": "${encryptedCard.encryptedExpiryMonth}",
        "encryptedExpiryYear": "${encryptedCard.encryptedExpiryYear}",
        "encryptedSecurityCode": "${encryptedCard.encryptedSecurityCode}"
      },
      "authenticationData": {
        "threeDSRequestData": {"nativeThreeDS": "preferred"}
      },
      "channel": determineChannel(),
      "returnUrl": returnUrl,
      "merchantAccount": Config.merchantAccount
    };
  }
}
