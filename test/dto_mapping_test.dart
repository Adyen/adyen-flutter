import 'dart:ui';

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
    final storedPaymentMethodConfiguration = StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: true,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback: (String input) => Future.value(true),
    );
    final dropInConfiguration = DropInConfiguration(
        environment: Environment.test,
        clientKey: demoClientKey,
        countryCode: countryCode,
        amount: Amount(value: amountValue, currency: currency),
        shopperLocale: shopperLocal,
        storedPaymentMethodConfiguration: storedPaymentMethodConfiguration);

    final dropInConfigurationDto = dropInConfiguration.toDTO("0.0.1", true);

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
    expect(dropInConfigurationDto.skipListWhenSinglePaymentMethod, false);
    expect(dropInConfigurationDto.showPreselectedStoredPaymentMethod, true);
    expect(dropInConfigurationDto.isRemoveStoredPaymentMethodEnabled, true);
    expect(dropInConfigurationDto.isPartialPaymentSupported, true);
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
      allowedCardNetworks: ["AMEX", "DISCOVER", "MASTERCARD", "VISA"],
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

  test(
      "when using apple pay configuration, then should parse to ApplePayConfigurationDTO",
      () {
    final shippingStartDate = DateTime.now();
    final shippingEndDate = shippingStartDate.add(const Duration(days: 5));
    final applePayConfiguration = ApplePayConfiguration(
        merchantId: "APPLE_PAY_MERCHANT_ID",
        merchantName: "APPLE_PAY_MERCHANT_NAME",
        allowOnboarding: true,
        applePaySummaryItems: [
          ApplePaySummaryItem(
            label: "Product A",
            amount: Amount(value: 2599, currency: "EUR"),
            type: ApplePaySummaryItemType.definite,
          )
        ],
        requiredBillingContactFields: [
          ApplePayContactField.emailAddress,
          ApplePayContactField.phoneNumber,
        ],
        billingContact: ApplePayContact(
          emailAddress: "flutterTest@adyen.com",
          phoneNumber: "0123456789",
        ),
        requiredShippingContactFields: [
          ApplePayContactField.emailAddress,
          ApplePayContactField.phoneNumber,
        ],
        shippingContact: ApplePayContact(
          emailAddress: "flutterTest@adyen.com",
          phoneNumber: "9876543210",
        ),
        applePayShippingType: ApplePayShippingType.servicePickup,
        allowShippingContactEditing: true,
        shippingMethods: [
          ApplePayShippingMethod(
            label: "Standard shipping",
            detail: "DHL",
            amount: Amount(value: 499, currency: "EUR"),
            identifier: "Identifier 1",
            startDate: shippingStartDate,
            endDate: shippingEndDate,
          )
        ],
        applicationData: null,
        supportedCountries: ["NL"],
        merchantCapability: ApplePayMerchantCapability.debit);

    final applePayConfigurationDTO = applePayConfiguration.toDTO();

    expect(applePayConfigurationDTO.merchantId, "APPLE_PAY_MERCHANT_ID");
    expect(applePayConfigurationDTO.merchantName, "APPLE_PAY_MERCHANT_NAME");
    expect(applePayConfigurationDTO.allowOnboarding, true);
    expect(
        applePayConfigurationDTO.summaryItems?.firstOrNull?.label, "Product A");
    expect(
        applePayConfigurationDTO.summaryItems?.firstOrNull?.amount.value, 2599);
    expect(applePayConfigurationDTO.summaryItems?.firstOrNull?.amount.currency,
        "EUR");
    expect(applePayConfigurationDTO.summaryItems?.firstOrNull?.type,
        ApplePaySummaryItemType.definite);
    expect(applePayConfigurationDTO.requiredBillingContactFields, [
      "emailAddress",
      "phoneNumber",
    ]);
    expect(applePayConfigurationDTO.billingContact?.emailAddress,
        "flutterTest@adyen.com");
    expect(applePayConfigurationDTO.billingContact?.phoneNumber, "0123456789");
    expect(applePayConfigurationDTO.requiredShippingContactFields, [
      "emailAddress",
      "phoneNumber",
    ]);
    expect(applePayConfigurationDTO.shippingContact?.emailAddress,
        "flutterTest@adyen.com");
    expect(applePayConfigurationDTO.shippingContact?.phoneNumber, "9876543210");
    expect(applePayConfigurationDTO.applePayShippingType,
        ApplePayShippingType.servicePickup);
    expect(applePayConfigurationDTO.allowShippingContactEditing, true);
    expect(applePayConfigurationDTO.shippingMethods?.firstOrNull?.label,
        "Standard shipping");
    expect(
        applePayConfigurationDTO.shippingMethods?.firstOrNull?.detail, "DHL");
    expect(applePayConfigurationDTO.shippingMethods?.firstOrNull?.amount.value,
        499);
    expect(
        applePayConfigurationDTO.shippingMethods?.firstOrNull?.amount.currency,
        "EUR");
    expect(applePayConfigurationDTO.shippingMethods?.firstOrNull?.identifier,
        "Identifier 1");
    expect(applePayConfigurationDTO.shippingMethods?.firstOrNull?.startDate,
        shippingStartDate.toIso8601String());
    expect(applePayConfigurationDTO.shippingMethods?.firstOrNull?.endDate,
        shippingEndDate.toIso8601String());
    expect(applePayConfigurationDTO.applicationData, null);
    expect(applePayConfigurationDTO.supportedCountries, ["NL"]);
    expect(applePayConfigurationDTO.merchantCapability,
        ApplePayMerchantCapability.debit);
  });

  test(
      "when using cash app pay configuration, then should parse to CashAppPayConfigurationDTO",
      () {
    const cashAppPayConfiguration = CashAppPayConfiguration(
      cashAppPayEnvironment: CashAppPayEnvironment.production,
      returnUrl: "RETURN_URL",
    );

    final cashAppPayConfigurationDTO = cashAppPayConfiguration.toDTO();

    expect(cashAppPayConfigurationDTO.cashAppPayEnvironment,
        CashAppPayEnvironment.production);
    expect(cashAppPayConfigurationDTO.returnUrl, "RETURN_URL");
  });

  test('when using 3DS theme, then should map to ui customization DTO', () {
    const theme = Adyen3DSTheme(
      primaryColor: Color(0xFF112233),
      textColor: Color(0xFFFFFFFF),
      inputDecorationTheme: Adyen3DSInputDecorationTheme(
        borderColor: Color(0xFF0A0B0C),
        textColor: Color(0xFF0D0E0F),
        borderWidth: 2,
        cornerRadius: 4,
      ),
    );

    final configuration = ThreeDS2Configuration(theme: theme);
    final dto = configuration.toDTO();

    final uiCustomization = dto.uiCustomization;
    expect(uiCustomization, isNotNull);
    expect(uiCustomization?.primaryButtonCustomization, isNull);
    expect(uiCustomization?.secondaryButtonCustomization, isNull);
    expect(uiCustomization?.inputCustomization?.borderColor, '#FF0A0B0C');
    expect(uiCustomization?.inputCustomization?.borderWidth, 2);
    expect(uiCustomization?.inputCustomization?.cornerRadius, 4);
    expect(uiCustomization?.inputCustomization?.textColor, '#FF0D0E0F');
  });

  test('when requestorAppURL set, then should pass through', () {
    final configuration = ThreeDS2Configuration(requestorAppURL: 'app://cb');

    final dto = configuration.toDTO();

    expect(dto.requestorAppURL, 'app://cb');
  });

  test('when theme has screen colors, then should map to screenCustomization', () {
    const theme = Adyen3DSTheme(
      backgroundColor: Color(0xFF111213),
      textColor: Color(0xFF141516),
    );

    final dto = ThreeDS2Configuration(theme: theme).toDTO();

    expect(dto.uiCustomization?.screenCustomization?.backgroundColor, '#FF111213');
    expect(dto.uiCustomization?.screenCustomization?.textColor, '#FF141516');
  });

  test('when header theme set, then should map all header fields', () {
    const headerTheme = Adyen3DSHeaderTheme(
      backgroundColor: Color(0xFF010203),
      textColor: Color(0xFF040506),
      fontSize: 18,
      cancelButtonText: 'Cancel',
    );
    const theme = Adyen3DSTheme(headerTheme: headerTheme);

    final dto = ThreeDS2Configuration(theme: theme, headingTitle: 'Heading').toDTO();

    final heading = dto.uiCustomization?.headingCustomization;
    expect(heading?.backgroundColor, '#FF010203');
    expect(heading?.textColor, '#FF040506');
    expect(heading?.textFontSize, 18);
    expect(heading?.buttonText, 'Cancel');
    expect(heading?.headerText, 'Heading');
  });

  test('when button themes set, then should map primary and secondary', () {
    const theme = Adyen3DSTheme(
      primaryButtonTheme: Adyen3DSButtonTheme(
        backgroundColor: Color(0xFF0A0B0C),
        textColor: Color(0xFF0D0E0F),
        cornerRadius: 6,
        fontSize: 15,
      ),
      secondaryButtonTheme: Adyen3DSButtonTheme(
        backgroundColor: Color(0xFF101112),
        textColor: Color(0xFF131415),
        cornerRadius: 8,
        fontSize: 13,
      ),
    );

    final dto = ThreeDS2Configuration(theme: theme).toDTO();

    final primary = dto.uiCustomization?.primaryButtonCustomization;
    final secondary = dto.uiCustomization?.secondaryButtonCustomization;
    expect(primary?.backgroundColor, '#FF0A0B0C');
    expect(primary?.textColor, '#FF0D0E0F');
    expect(primary?.cornerRadius, 6);
    expect(primary?.textFontSize, 15);
    expect(secondary?.backgroundColor, '#FF101112');
    expect(secondary?.textColor, '#FF131415');
    expect(secondary?.cornerRadius, 8);
    expect(secondary?.textFontSize, 13);
  });

  test('when both headingTitle and headerTheme provided, headerTheme should win for style', () {
    const theme = Adyen3DSTheme(
      headerTheme: Adyen3DSHeaderTheme(
        backgroundColor: Color(0xFF212223),
        textColor: Color(0xFF242526),
        fontSize: 20,
        cancelButtonText: 'Close',
      ),
    );

    final dto = ThreeDS2Configuration(
      headingTitle: 'Preferred heading',
      theme: theme,
    ).toDTO();

    final heading = dto.uiCustomization?.headingCustomization;
    expect(heading?.headerText, 'Preferred heading');
    expect(heading?.backgroundColor, '#FF212223');
    expect(heading?.textColor, '#FF242526');
    expect(heading?.textFontSize, 20);
    expect(heading?.buttonText, 'Close');
  });

  test('when toolbar title is set, then should map to toolbar header text', () {
    final configuration = ThreeDS2Configuration(
      headingTitle: 'Challenge',
    );

    final dto = configuration.toDTO();

    expect(dto.uiCustomization, isNotNull);
    expect(dto.uiCustomization?.headingCustomization, isNotNull);
    expect(dto.uiCustomization?.headingCustomization?.headerText, 'Challenge');
  });

  test('color to hex should include alpha channel', () {
    const color = Color(0x80112233);
    expect(color.toHexString(), '#80112233');
  });
}
