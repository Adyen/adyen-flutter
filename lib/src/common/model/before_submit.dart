import 'address.dart';
import 'shopper_name.dart';

class BeforeSubmitData {
  final Address? billingAddress;
  final Address? deliveryAddress;
  final ShopperName? shopperName;
  final String? shopperEmail;

  const BeforeSubmitData({
    this.billingAddress,
    this.deliveryAddress,
    this.shopperName,
    this.shopperEmail,
  });
}

sealed class BeforeSubmitResult {
  const BeforeSubmitResult();
}

class BeforeSubmitProceed extends BeforeSubmitResult {
  final BeforeSubmitData data;
  final String? sessionData;

  const BeforeSubmitProceed({
    required this.data,
    this.sessionData,
  });
}

class BeforeSubmitAbort extends BeforeSubmitResult {
  const BeforeSubmitAbort();
}

typedef OnBeforeSubmitCallback = Future<BeforeSubmitResult> Function(
  BeforeSubmitData data,
);
