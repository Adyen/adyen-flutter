import 'dart:convert';

import '../common/model/address.dart';
import '../common/model/amount.dart';
import '../common/model/billing_address_mode.dart';
import '../common/model/card_callbacks/bin_lookup_data.dart';
import '../common/model/action_component_data.dart';
import '../common/model/analytics_configuration.dart';
import '../common/model/before_submit.dart';
import '../common/model/checkout_configuration.dart';
import '../common/model/checkout_results.dart';
import '../common/model/cse/encrypted_card.dart';
import '../common/model/cse/unencrypted_card.dart';
import '../common/model/environment.dart';
import '../common/model/field_visibility.dart';
import '../common/model/google_pay_environment.dart';
import '../common/model/payment_component_data.dart';
import '../common/model/payment_method.dart';
import '../common/model/payment_method_configurations/card_configuration.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_authorization_result.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_authorized_payment.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_contact.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_coupon_code_update.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_merchant_capability.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_payment_error.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_payment_error_type.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_shipping_contact_update.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method_update.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_shipping_type.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';
import '../common/model/payment_method_configurations/apple_pay/apple_pay_summary_item_type.dart';
import '../common/model/payment_method_configurations/card/installment_configuration.dart';
import '../common/model/payment_method_configurations/card/installment_options.dart';
import '../common/model/payment_method_configurations/google_pay/google_pay_configuration.dart';
import '../common/model/payment_method_configurations/google_pay/merchant_info.dart';
import '../common/model/total_price_status.dart';
import '../common/model/payment_method_configurations/google_pay/shipping_address_parameters.dart';
import '../common/model/session_response.dart';
import '../common/model/shopper_name.dart';
import '../common/model/stored_payment_method.dart';
import '../components/apple_pay/model/apple_pay_button_style.dart';
import '../components/apple_pay/model/apple_pay_button_theme.dart';
import '../components/apple_pay/model/apple_pay_button_type.dart';
import '../generated/platform_api.g.dart';

extension SessionResponseMapper on SessionResponse {
  SessionResponseDTO toDTO() => SessionResponseDTO(
        id: id,
        sessionData: sessionData,
      );
}

extension AmountMapper on Amount {
  AmountDTO toDTO() => AmountDTO(
        currency: currency,
        value: value,
      );
}

extension AnalyticsConfigurationMapper on AnalyticsConfiguration {
  AnalyticsConfigurationDTO toDTO() => AnalyticsConfigurationDTO(
        enabled: enabled,
      );
}

extension CheckoutConfigurationMapper on CheckoutConfiguration {
  CheckoutConfigurationDTO toDTO() => CheckoutConfigurationDTO(
        environment: environment.toDTO(),
        clientKey: clientKey,
        countryCode: countryCode?.toUpperCase(),
        amount: amount?.toDTO(),
        analyticsConfiguration: analyticsConfiguration.toDTO(),
        showSubmitButton: showSubmitButton,
        cardConfiguration: cardConfiguration?.toDTO(),
        applePayConfiguration: applePayConfiguration?.toDTO(),
        googlePayConfiguration: googlePayConfiguration?.toDTO(),
      );
}

extension EnvironmentMapper on Environment {
  EnvironmentDTO toDTO() => switch (this) {
        Environment.test => EnvironmentDTO.test,
        Environment.liveEurope => EnvironmentDTO.liveEurope,
        Environment.liveUnitedStates => EnvironmentDTO.liveUnitedStates,
        Environment.liveAustralia => EnvironmentDTO.liveAustralia,
        Environment.liveApse => EnvironmentDTO.liveApse,
        Environment.liveIndia => EnvironmentDTO.liveIndia,
        Environment.liveNea => EnvironmentDTO.liveNea,
      };
}

extension CardConfigurationMapper on CardConfiguration {
  CardConfigurationDTO toDTO() => CardConfigurationDTO(
        billingAddressMode: billingAddressMode.toDTO(),
        koreanAuthenticationVisibility: koreanAuthenticationVisibility.toDTO(),
        showCardholderName: showCardholderName,
        showSecurityCode: showSecurityCode,
        showSecurityCodeForStoredCard: showSecurityCodeForStoredCard,
        showStorePaymentMethod: showStorePaymentMethod,
        showSupportedCardBrandLogos: showSupportedCardBrandLogos,
        socialSecurityNumberVisibility: socialSecurityNumberVisibility.toDTO(),
        supportedCardBrands: supportedCardBrands,
        installmentConfiguration: installmentConfiguration?.toDTO(),
        hasOnBinChange: onBinChange != null,
        hasOnBinLookup: onBinLookup != null,
      );
}

extension BillingAddressModeMapper on BillingAddressMode {
  BillingAddressModeDTO toDTO() => switch (this) {
        BillingAddressMode.none => BillingAddressModeDTO.none,
        BillingAddressMode.postalCode => BillingAddressModeDTO.postalCode,
      };
}

extension FieldVisibilityMapper on FieldVisibility {
  FieldVisibilityDTO toDTO() => switch (this) {
        FieldVisibility.show => FieldVisibilityDTO.show,
        FieldVisibility.hide => FieldVisibilityDTO.hide,
        FieldVisibility.auto => FieldVisibilityDTO.auto,
      };
}

extension InstallmentConfigurationMapper on InstallmentConfiguration {
  InstallmentConfigurationDTO toDTO() => InstallmentConfigurationDTO(
        options: <InstallmentOptionsDTO>[
          if (defaultOptions case final options?) options.toDTO(),
          ...?cardBasedOptions?.map((options) => options.toDTO()),
        ],
        showInstallmentAmount: showInstallmentAmount,
      );
}

extension InstallmentOptionsMapper on InstallmentOptions {
  InstallmentOptionsDTO toDTO() => InstallmentOptionsDTO(
        values: values,
        includesRevolving: includesRevolving,
        cardBrand: switch (this) {
          CardBasedInstallmentOptions options => options.cardBrand,
          DefaultInstallmentOptions() => null,
        },
      );
}

extension GooglePayConfigurationMapper on GooglePayConfiguration {
  GooglePayConfigurationDTO toDTO() => GooglePayConfigurationDTO(
        googlePayEnvironment: switch (googlePayEnvironment) {
          GooglePayEnvironment.test => GooglePayEnvironmentDTO.test,
          GooglePayEnvironment.production => GooglePayEnvironmentDTO.production,
        },
        merchantAccount: merchantAccount,
        merchantInfo: merchantInfo?.toDTO(),
        totalPriceStatus: totalPriceStatus?.toDTO(),
        emailRequired: emailRequired,
        existingPaymentMethodRequired: existingPaymentMethodRequired,
        shippingAddressRequired: shippingAddressRequired,
        shippingAddressParameters: shippingAddressParameters?.toDTO(),
      );
}

extension MerchantInfoMapper on MerchantInfo {
  MerchantInfoDTO toDTO() => MerchantInfoDTO(
        merchantName: merchantName,
        merchantId: merchantId,
      );
}

extension ShippingAddressParametersMapper on ShippingAddressParameters {
  ShippingAddressParametersDTO toDTO() => ShippingAddressParametersDTO(
        allowedCountryCodes: allowedCountryCodes,
        isPhoneNumberRequired: isPhoneNumberRequired,
      );
}

extension TotalPriceStatusMapper on TotalPriceStatus {
  TotalPriceStatusDTO toDTO() => switch (this) {
        TotalPriceStatus.notCurrentlyKnown =>
          TotalPriceStatusDTO.notCurrentlyKnown,
        TotalPriceStatus.estimated => TotalPriceStatusDTO.estimated,
        TotalPriceStatus.finalPrice => TotalPriceStatusDTO.finalPrice,
      };
}

extension ApplePayConfigurationMapper on ApplePayConfiguration {
  ApplePayConfigurationDTO toDTO() => ApplePayConfigurationDTO(
        merchantId: merchantId,
        merchantName: merchantName,
        allowOnboarding: allowOnboarding,
        summaryItems: applePaySummaryItems
            ?.map((summaryItem) => summaryItem.toDTO())
            .toList(),
        requiredBillingContactFields:
            requiredBillingContactFields?.map((field) => field.name).toList(),
        billingContact: billingContact?.toDTO(),
        requiredShippingContactFields:
            requiredShippingContactFields?.map((field) => field.name).toList(),
        shippingContact: shippingContact?.toDTO(),
        shippingType: applePayShippingType?.toDTO(),
        allowShippingContactEditing: allowShippingContactEditing,
        shippingMethods: shippingMethods
            ?.map((shippingMethod) => shippingMethod.toDTO())
            .toList(),
        applicationData: applicationData,
        supportedCountries: supportedCountries,
        merchantCapability: merchantCapability?.toDTO(),
        supportsCouponCode: supportsCouponCode,
        couponCode: couponCode,
        buttonStyle: buttonStyle?.toDTO(),
        buttonWidth: buttonWidth,
        buttonHeight: buttonHeight,
        hasOnSelectShippingMethod: onSelectShippingMethod != null,
        hasOnSelectShippingContact: onSelectShippingContact != null,
        hasOnChangeCouponCode: onChangeCouponCode != null,
        hasOnAuthorize: onAuthorize != null,
      );
}

extension ApplePaySummaryItemMapper on ApplePaySummaryItem {
  ApplePaySummaryItemDTO toDTO() => ApplePaySummaryItemDTO(
        label: label,
        amount: amount.toDTO(),
        type: switch (type) {
          ApplePaySummaryItemType.pending => ApplePaySummaryItemTypeDTO.pending,
          ApplePaySummaryItemType.definite =>
            ApplePaySummaryItemTypeDTO.definite,
        },
      );
}

extension ApplePayContactMapper on ApplePayContact {
  ApplePayContactDTO toDTO() => ApplePayContactDTO(
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        givenName: givenName,
        familyName: familyName,
        phoneticGivenName: phoneticGivenName,
        phoneticFamilyName: phoneticFamilyName,
        addressLines: addressLines,
        subLocality: subLocality,
        city: city,
        postalCode: postalCode,
        subAdministrativeArea: subAdministrativeArea,
        administrativeArea: administrativeArea,
        country: country,
        countryCode: countryCode,
      );
}

extension ApplePayShippingMethodMapper on ApplePayShippingMethod {
  ApplePayShippingMethodDTO toDTO() => ApplePayShippingMethodDTO(
        label: label,
        detail: detail,
        amount: amount.toDTO(),
        identifier: identifier,
        startDate: startDate?.toUtc().toIso8601String(),
        endDate: endDate?.toUtc().toIso8601String(),
      );
}

extension ApplePayShippingTypeMapper on ApplePayShippingType {
  ApplePayShippingTypeDTO toDTO() => switch (this) {
        ApplePayShippingType.shipping => ApplePayShippingTypeDTO.shipping,
        ApplePayShippingType.delivery => ApplePayShippingTypeDTO.delivery,
        ApplePayShippingType.storePickup => ApplePayShippingTypeDTO.storePickup,
        ApplePayShippingType.servicePickup =>
          ApplePayShippingTypeDTO.servicePickup,
      };
}

extension ApplePayMerchantCapabilityMapper on ApplePayMerchantCapability {
  ApplePayMerchantCapabilityDTO toDTO() => switch (this) {
        ApplePayMerchantCapability.debit => ApplePayMerchantCapabilityDTO.debit,
        ApplePayMerchantCapability.credit =>
          ApplePayMerchantCapabilityDTO.credit,
      };
}

extension ApplePayButtonStyleMapper on ApplePayButtonStyle {
  ApplePayButtonStyleDTO toDTO() => ApplePayButtonStyleDTO(
        theme: switch (theme) {
          ApplePayButtonTheme.white => ApplePayButtonThemeDTO.white,
          ApplePayButtonTheme.whiteOutline =>
            ApplePayButtonThemeDTO.whiteWithLine,
          ApplePayButtonTheme.black => ApplePayButtonThemeDTO.black,
          ApplePayButtonTheme.automatic => null,
          null => null,
        },
        type: type?.toDTO(),
        cornerRadius: cornerRadius,
      );
}

extension ApplePayButtonTypeMapper on ApplePayButtonType {
  ApplePayButtonTypeDTO toDTO() => ApplePayButtonTypeDTO.values[index];
}

extension BeforeSubmitDataMapper on BeforeSubmitData {
  BeforeSubmitDataDTO toDTO() => BeforeSubmitDataDTO(
        billingAddress: billingAddress?.toDTO(),
        deliveryAddress: deliveryAddress?.toDTO(),
        shopperName: shopperName?.toDTO(),
        shopperEmail: shopperEmail,
      );
}

extension BeforeSubmitResultMapper on BeforeSubmitResult {
  BeforeSubmitResultDTO toDTO() => switch (this) {
        BeforeSubmitProceed(data: final data, sessionData: final sessionData) =>
          BeforeSubmitResultDTO(
            isAborted: false,
            data: data.toDTO(),
            sessionData: sessionData,
          ),
        BeforeSubmitAbort() => BeforeSubmitResultDTO(isAborted: true),
      };
}

extension BeforeSubmitDataDTOMapper on BeforeSubmitDataDTO {
  BeforeSubmitData toModel() => BeforeSubmitData(
        billingAddress: billingAddress?.toModel(),
        deliveryAddress: deliveryAddress?.toModel(),
        shopperName: shopperName?.toModel(),
        shopperEmail: shopperEmail,
      );
}

extension AddressMapper on Address {
  AddressDTO toDTO() => AddressDTO(
        city: city,
        country: country,
        houseNumberOrName: _joinNonEmpty(houseNumberOrName, apartment),
        postalCode: postalCode,
        stateOrProvince: stateOrProvince,
        street: street,
      );
}

extension AddressDTOMapper on AddressDTO {
  Address toModel() => Address(
        city: city,
        country: country,
        houseNumberOrName: houseNumberOrName,
        postalCode: postalCode,
        stateOrProvince: stateOrProvince,
        street: street,
      );
}

extension ShopperNameMapper on ShopperName {
  ShopperNameDTO toDTO() => ShopperNameDTO(
        firstName: firstName,
        lastName: lastName,
        infix: infix,
        gender: gender,
      );
}

extension ShopperNameDTOMapper on ShopperNameDTO {
  ShopperName toModel() => ShopperName(
        firstName: firstName,
        lastName: lastName,
        infix: infix,
        gender: gender,
      );
}

extension ApplePaySummaryItemDTOMapper on ApplePaySummaryItemDTO {
  ApplePaySummaryItem toModel() => ApplePaySummaryItem(
        label: label,
        amount: Amount(value: amount.value, currency: amount.currency),
        type: switch (type) {
          ApplePaySummaryItemTypeDTO.pending => ApplePaySummaryItemType.pending,
          ApplePaySummaryItemTypeDTO.definite =>
            ApplePaySummaryItemType.definite,
        },
      );
}

extension ApplePayShippingMethodDTOMapper on ApplePayShippingMethodDTO {
  ApplePayShippingMethod toModel() => ApplePayShippingMethod(
        label: label,
        detail: detail,
        amount: Amount(value: amount.value, currency: amount.currency),
        identifier: identifier,
        startDate: startDate == null ? null : DateTime.tryParse(startDate!),
        endDate: endDate == null ? null : DateTime.tryParse(endDate!),
      );
}

extension ApplePayContactDTOMapper on ApplePayContactDTO {
  ApplePayContact toModel() => ApplePayContact(
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        givenName: givenName,
        familyName: familyName,
        phoneticGivenName: phoneticGivenName,
        phoneticFamilyName: phoneticFamilyName,
        addressLines: addressLines,
        subLocality: subLocality,
        city: city,
        postalCode: postalCode,
        subAdministrativeArea: subAdministrativeArea,
        administrativeArea: administrativeArea,
        country: country,
        countryCode: countryCode,
      );
}

extension ApplePayAuthorizedPaymentDTOMapper on ApplePayAuthorizedPaymentDTO {
  ApplePayAuthorizedPayment toModel() => ApplePayAuthorizedPayment(
        token: token,
        network: network,
        billingContact: billingContact?.toModel(),
        shippingContact: shippingContact?.toModel(),
        shippingMethod: shippingMethod?.toModel(),
      );
}

extension ApplePayShippingMethodUpdateMapper on ApplePayShippingMethodUpdate {
  ApplePayShippingMethodUpdateDTO toDTO() => ApplePayShippingMethodUpdateDTO(
        summaryItems: summaryItems.map((item) => item.toDTO()).toList(),
      );
}

extension ApplePayShippingContactUpdateMapper on ApplePayShippingContactUpdate {
  ApplePayShippingContactUpdateDTO toDTO() => ApplePayShippingContactUpdateDTO(
        summaryItems: summaryItems.map((item) => item.toDTO()).toList(),
        shippingMethods:
            shippingMethods?.map((method) => method.toDTO()).toList(),
        errors: errors?.map((error) => error.toDTO()).toList(),
      );
}

extension ApplePayCouponCodeUpdateMapper on ApplePayCouponCodeUpdate {
  ApplePayCouponCodeUpdateDTO toDTO() => ApplePayCouponCodeUpdateDTO(
        summaryItems: summaryItems.map((item) => item.toDTO()).toList(),
        shippingMethods:
            shippingMethods?.map((method) => method.toDTO()).toList(),
        errors: errors?.map((error) => error.toDTO()).toList(),
      );
}

extension ApplePayAuthorizationResultMapper on ApplePayAuthorizationResult {
  ApplePayAuthorizationResultDTO toDTO() => switch (this) {
        ApplePayAuthorizationSuccess() =>
          ApplePayAuthorizationResultDTO(isSuccess: true),
        ApplePayAuthorizationFailure(errors: final errors) =>
          ApplePayAuthorizationResultDTO(
            isSuccess: false,
            errors: errors.map((error) => error.toDTO()).toList(),
          ),
      };
}

extension ApplePayPaymentErrorMapper on ApplePayPaymentError {
  ApplePayPaymentErrorDTO toDTO() => ApplePayPaymentErrorDTO(
        type: switch (type) {
          ApplePayPaymentErrorType.billingAddress =>
            ApplePayPaymentErrorTypeDTO.billingAddress,
          ApplePayPaymentErrorType.shippingAddress =>
            ApplePayPaymentErrorTypeDTO.shippingAddress,
          ApplePayPaymentErrorType.contact =>
            ApplePayPaymentErrorTypeDTO.contact,
          ApplePayPaymentErrorType.couponCode =>
            ApplePayPaymentErrorTypeDTO.couponCode,
          ApplePayPaymentErrorType.shippingAddressUnserviceable =>
            ApplePayPaymentErrorTypeDTO.shippingAddressUnserviceable,
          ApplePayPaymentErrorType.couponCodeExpired =>
            ApplePayPaymentErrorTypeDTO.couponCodeExpired,
          ApplePayPaymentErrorType.unknown =>
            ApplePayPaymentErrorTypeDTO.unknown,
        },
        field: field?.name,
        localizedDescription: localizedDescription,
      );
}

extension PaymentComponentDataDTOMapper on PaymentComponentDataDTO {
  PaymentComponentData fromDTO() => PaymentComponentData.fromJson(
        _decodeObject(dataJson, 'PaymentComponentData'),
      );
}

extension ActionComponentDataDTOMapper on ActionComponentDataDTO {
  ActionComponentData fromDTO() => ActionComponentData.fromJson(
        _decodeObject(dataJson, 'ActionComponentData'),
      );
}

extension CheckoutEventMapper on CheckoutEventDTO {
  BinLookupData? get mappedBinLookupData =>
      binLookupData?.isEmpty == true ? null : binLookupData?.first.toModel();
}

extension BinLookupDataDTOMapper on BinLookupDataDTO {
  BinLookupData toModel() => BinLookupData(
        issuingCountryCode: issuingCountryCode,
        brands: brands.map((brand) => brand.toModel()).toList(),
      );
}

extension BinLookupBrandDTOMapper on BinLookupBrandDTO {
  BinLookupBrand toModel() => BinLookupBrand(
        brand: brand,
        supported: supported,
        paymentMethodVariant: paymentMethodVariant,
      );
}

extension UnencryptedCardMapper on UnencryptedCard {
  UnencryptedCardDTO toDTO() => UnencryptedCardDTO(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
      );
}

extension EncryptedCardDTOMapper on EncryptedCardDTO {
  EncryptedCard toModel() => EncryptedCard(
        encryptedCardNumber: encryptedCardNumber,
        encryptedExpiryMonth: encryptedExpiryMonth,
        encryptedExpiryYear: encryptedExpiryYear,
        encryptedSecurityCode: encryptedSecurityCode,
      );
}

extension SubmitResultMapper on SubmitResult {
  SubmitResultDTO toDTO() => switch (this) {
        SubmitCompletion(resultCode: final resultCode) => SubmitResultDTO(
            type: SubmitResultTypeDTO.completion,
            resultCode: resultCode,
          ),
        SubmitAction(action: final action) => SubmitResultDTO(
            type: SubmitResultTypeDTO.action,
            actionJson: jsonEncode(action.data),
          ),
        SubmitRetry(errorMessage: final errorMessage) => SubmitResultDTO(
            type: SubmitResultTypeDTO.retry,
            errorMessage: errorMessage,
          ),
      };
}

extension AdditionalDetailsResultMapper on AdditionalDetailsResult {
  AdditionalDetailsResultDTO toDTO() => switch (this) {
        AdditionalDetailsCompletion(resultCode: final resultCode) =>
          AdditionalDetailsResultDTO(resultCode: resultCode),
      };
}

extension CheckoutSetupResultMapper on CheckoutSetupResultDTO {
  PaymentMethodsParts toPaymentMethods() => PaymentMethodsParts(
        regular:
            _decodeList(regularPaymentMethodsJson, 'regular payment methods'),
        stored: _decodeStoredList(
          storedPaymentMethodsJson,
          'stored payment methods',
        ),
      );
}

class PaymentMethodsParts {
  final List<PaymentMethod> regular;
  final List<StoredPaymentMethod> stored;

  const PaymentMethodsParts({
    required this.regular,
    required this.stored,
  });
}

Map<String, dynamic> _decodeObject(String json, String name) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) {
    throw FormatException('$name must be a JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

List<PaymentMethod> _decodeList(String json, String name) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    throw FormatException('$name must be a JSON list.');
  }
  return decoded
      .map((item) => PaymentMethod.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<StoredPaymentMethod> _decodeStoredList(String json, String name) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    throw FormatException('$name must be a JSON list.');
  }
  return decoded
      .map((item) =>
          StoredPaymentMethod.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

String? _joinNonEmpty(String? first, String? second) {
  final values = [first, second]
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList();
  return values.isEmpty ? null : values.join(' ');
}
