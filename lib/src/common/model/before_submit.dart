import 'package:adyen_checkout/src/common/model/address.dart';
import 'package:adyen_checkout/src/common/model/shopper_name.dart';

/// Shopper data collected by the component, inspectable/modifiable before the
/// sessions flow submits the `/payments` request.
///
/// Fields left `null` keep the value collected by the component; they are
/// not cleared.
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

  @override
  String toString() {
    return 'BeforeSubmitData('
        'billingAddress: $billingAddress, '
        'deliveryAddress: $deliveryAddress, '
        'shopperName: $shopperName, '
        'shopperEmail: $shopperEmail)';
  }
}

/// The result of the `onBeforeSubmit` callback.
sealed class BeforeSubmitResult {}

/// Continue the sessions submission flow.
class BeforeSubmitProceed extends BeforeSubmitResult {
  /// The shopper data to continue with. Use unmodified [BeforeSubmitData]
  /// from the callback to proceed as-is, or return modified fields.
  final BeforeSubmitData data;

  /// The session data returned by your server after patching the session,
  /// if you did so during this callback. Leave `null` otherwise.
  final String? sessionData;

  BeforeSubmitProceed({
    required this.data,
    this.sessionData,
  });
}

/// Stop the submission flow and reset the component to its ready state.
///
/// Does NOT trigger the session's error/failure result.
class BeforeSubmitAbort extends BeforeSubmitResult {}

/// Callback invoked before the sessions flow submits payment data.
///
/// Return [BeforeSubmitProceed] to continue, optionally with modified
/// shopper data or patched session data. Return [BeforeSubmitAbort] to stop
/// the flow and reset the component state.
typedef OnBeforeSubmitCallback = Future<BeforeSubmitResult> Function(
  BeforeSubmitData data,
);
