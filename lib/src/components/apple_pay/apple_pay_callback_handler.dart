import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

/// Encapsulates the merchant-provided Apple Pay callbacks for a single
/// component instance and translates between DTOs and public models.
class ApplePayCallbackHandler {
  ApplePayCallbackHandler(this._configurationProvider);

  final ApplePayConfiguration Function() _configurationProvider;

  ApplePayConfiguration get _configuration => _configurationProvider();

  Future<ApplePayShippingMethodUpdateDTO> onSelectShippingMethod(
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final shippingMethodUpdate =
          await _configuration.onSelectShippingMethod?.call(
        shippingMethod.fromDTO(),
        summaryItems.fromDTOs(),
      );
      return shippingMethodUpdate?.toDTO() ??
          ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePaySelectShippingMethod failed: $exception');
      return ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);
    }
  }

  Future<ApplePayShippingContactUpdateDTO> onSelectShippingContact(
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final shippingContactUpdate =
          await _configuration.onSelectShippingContact?.call(
        contact.fromDTO(),
        summaryItems.fromDTOs(),
      );
      return shippingContactUpdate?.toDTO() ??
          ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePaySelectShippingContact failed: $exception');
      return ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);
    }
  }

  Future<ApplePayCouponCodeUpdateDTO> onChangeCouponCode(
    String couponCode,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final couponCodeUpdate = await _configuration.onChangeCouponCode?.call(
        couponCode,
        summaryItems.fromDTOs(),
      );
      return couponCodeUpdate?.toDTO() ??
          ApplePayCouponCodeUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePayChangeCouponCode failed: $exception');
      return ApplePayCouponCodeUpdateDTO(summaryItems: summaryItems);
    }
  }

  Future<ApplePayAuthorizationResultDTO> onAuthorize(
    ApplePayAuthorizedPaymentDTO payment,
  ) async {
    try {
      final authorizationResult =
          await _configuration.onAuthorize?.call(payment.fromDTO());
      return authorizationResult?.toDTO() ??
          ApplePayAuthorizationResultDTO(isSuccess: true);
    } catch (exception) {
      AdyenLogger.instance.print('onApplePayAuthorize failed: $exception');
      return ApplePayAuthorizationResultDTO(isSuccess: false);
    }
  }
}
