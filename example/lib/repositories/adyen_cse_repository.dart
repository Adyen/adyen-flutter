import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenCseRepository extends AdyenBaseRepository {
  AdyenCseRepository({required super.service});

  Future<Map<String, dynamic>> payments({
    required EncryptedCard encryptedCard,
    String? threeDS2SdkVersion,
  }) async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";
    final requestBody = <String, Object>{
      "amount": {"currency": "EUR", "value": 10000},
      "reference": "flutter-test_${DateTime.now().millisecondsSinceEpoch}",
      "paymentMethod": {
        "type": "scheme",
        "encryptedCardNumber": "${encryptedCard.encryptedCardNumber}",
        "encryptedExpiryMonth": "${encryptedCard.encryptedExpiryMonth}",
        "encryptedExpiryYear": "${encryptedCard.encryptedExpiryYear}",
        "encryptedSecurityCode": "${encryptedCard.encryptedSecurityCode}",
        "threeDS2SdkVersion": threeDS2SdkVersion
      },
      "authenticationData": {
        "threeDSRequestData": {"nativeThreeDS": "preferred"}
      },
      "channel": determineChannel(),
      "returnUrl": returnUrl,
      "merchantAccount": Config.merchantAccount
    };

    return await service.postPayments(requestBody);
  }

  Future<Map<String, dynamic>> paymentsDetails(
      Map<String, dynamic> detailsRequestBody) async {
    return await service.postPaymentsDetails(detailsRequestBody);
  }

  Future<Map<String, dynamic>> cardDetails(String encryptedCardNumber) async {
    final requestBody = {
      "merchantAccount": Config.merchantAccount,
      "encryptedCardNumber": encryptedCardNumber,
    };
    return await service.postCardDetails(requestBody);
  }
}
