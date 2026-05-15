import 'package:adyen_checkout/src/common/model/amount.dart';

class ApplePayMultiTokenContext {
  final String merchantId;
  final String externalId;
  final String merchantName;
  final String? merchantDomain;
  final Amount amount;

  const ApplePayMultiTokenContext({
    required this.merchantId,
    required this.externalId,
    required this.merchantName,
    this.merchantDomain,
    required this.amount,
  });
}
