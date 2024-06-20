import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'when drop in configuration is provided, then should map to DropInConfigurationDTO',
      () {
    const demoClientKey = "1234567890";
    const countryCode = "US";
    const currency = "USD";
    const amountValue = 1286;
    const shopperLocal = "en-US";
    final dropInConfiguration = DropInConfiguration(
      environment: Environment.test,
      clientKey: demoClientKey,
      countryCode: countryCode,
      amount: Amount(value: amountValue, currency: currency),
      shopperLocale: shopperLocal,
    );

    final dropInConfigurationDto = dropInConfiguration.toDTO("0.0.1");

    expect(dropInConfigurationDto.environment, Environment.test);
    expect(dropInConfigurationDto.clientKey, demoClientKey);
    expect(dropInConfigurationDto.countryCode, countryCode);
    expect(dropInConfigurationDto.amount?.value, amountValue);
    expect(dropInConfigurationDto.amount?.currency, currency);
    expect(dropInConfigurationDto.amount.runtimeType == AmountDTO, true);
    expect(dropInConfigurationDto.shopperLocale, "en-US");
    expect(dropInConfigurationDto.cardConfigurationDTO, null);
    expect(dropInConfigurationDto.applePayConfigurationDTO, null);
    expect(dropInConfigurationDto.googlePayConfigurationDTO, null);
    expect(dropInConfigurationDto.cashAppPayConfigurationDTO, null);
    expect(dropInConfigurationDto.analyticsOptionsDTO.enabled, true);
    expect(dropInConfigurationDto.isRemoveStoredPaymentMethodEnabled, false);
    expect(dropInConfigurationDto.skipListWhenSinglePaymentMethod, false);
  });

  test(
      "when using card configuration, then should parse to CardConfigurationDTO",
      () {
    const cardConfiguration = CardConfiguration(
      holderNameRequired: true,
      addressMode: AddressMode.full,
      showStorePaymentField: true,
      showCvcForStoredCard: true,
      showCvc: true,
      kcpFieldVisibility: FieldVisibility.hide,
      socialSecurityNumberFieldVisibility: FieldVisibility.show,
      supportedCardTypes: ["amex"],
    );

    final cardConfigurationDTO = cardConfiguration.toDTO();

    expect(cardConfigurationDTO.holderNameRequired, true);
    expect(cardConfigurationDTO.addressMode, AddressMode.full);
    expect(cardConfigurationDTO.showStorePaymentField, true);
    expect(cardConfigurationDTO.showCvcForStoredCard, true);
    expect(cardConfigurationDTO.showCvc, true);
    expect(cardConfigurationDTO.kcpFieldVisibility, FieldVisibility.hide);
    expect(cardConfigurationDTO.socialSecurityNumberFieldVisibility,
        FieldVisibility.show);
    expect(cardConfigurationDTO.supportedCardTypes, ["amex"]);
  });

  test(
      "when using google pay configuration, then should parse to GooglePayConfigurationDTO",
      () {
    final googlePayConfiguration = GooglePayConfiguration(
      googlePayEnvironment: GooglePayEnvironment.production,
      merchantAccount: "GOOGLE_PAY_MERCHANT_ACCOUNT",
      merchantInfo: MerchantInfo(
        merchantName: "GOOGLE_PAY_MERCHANT_NAME",
        merchantId: "GOOGLE_PAY_MERCHANT_ID",
      ),
      totalPriceStatus: TotalPriceStatus.finalPrice,
      allowedCardNetworks: [
        "AMEX",
        "DISCOVER",
        "MASTERCARD",
        "VISA"
      ],
      allowedAuthMethods: [CardAuthMethod.cryptogram3DS],
      allowPrepaidCards: true,
      allowCreditCards: true,
      assuranceDetailsRequired: false,
      emailRequired: true,
      existingPaymentMethodRequired: true,
      shippingAddressRequired: true,
      shippingAddressParameters: ShippingAddressParameters(
        allowedCountryCodes: ["NL"],
        isPhoneNumberRequired: true,
      ),
      billingAddressRequired: true,
      billingAddressParameters:
          BillingAddressParameters(format: "MIN", isPhoneNumberRequired: false),
    );

    final googlePayConfigurationDTO = googlePayConfiguration.toDTO();

    expect(googlePayConfigurationDTO.googlePayEnvironment,
        GooglePayEnvironment.production);
    expect(googlePayConfigurationDTO.merchantAccount,
        "GOOGLE_PAY_MERCHANT_ACCOUNT");
    expect(googlePayConfigurationDTO.merchantInfoDTO?.merchantId,
        "GOOGLE_PAY_MERCHANT_ID");
    expect(googlePayConfigurationDTO.merchantInfoDTO?.merchantName,
        "GOOGLE_PAY_MERCHANT_NAME");
    expect(googlePayConfigurationDTO.totalPriceStatus,
        TotalPriceStatus.finalPrice);
    expect(googlePayConfigurationDTO.allowedCardNetworks,
        ["AMEX", "DISCOVER", "MASTERCARD", "VISA"]);
    expect(googlePayConfigurationDTO.allowedAuthMethods, ["cryptogram3DS"]);
    expect(googlePayConfigurationDTO.allowPrepaidCards, true);
    expect(googlePayConfigurationDTO.allowCreditCards, true);
    expect(googlePayConfigurationDTO.assuranceDetailsRequired, false);
    expect(googlePayConfigurationDTO.emailRequired, true);
    expect(googlePayConfigurationDTO.existingPaymentMethodRequired, true);
    expect(googlePayConfigurationDTO.shippingAddressRequired, true);
    expect(
        googlePayConfigurationDTO
            .shippingAddressParametersDTO?.allowedCountryCodes,
        ["NL"]);
    expect(
        googlePayConfigurationDTO
            .shippingAddressParametersDTO?.isPhoneNumberRequired,
        true);
    expect(googlePayConfigurationDTO.billingAddressRequired, true);
    expect(
        googlePayConfigurationDTO.billingAddressParametersDTO?.format, "MIN");
    expect(
        googlePayConfigurationDTO
            .billingAddressParametersDTO?.isPhoneNumberRequired,
        false);
  });
}
