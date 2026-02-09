import 'dart:convert';
import 'dart:ui';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

extension AnalyticsOptionsMapper on AnalyticsOptions {
  AnalyticsOptionsDTO toDTO(String version) => AnalyticsOptionsDTO(
        enabled: enabled,
        version: version,
      );
}

extension DropInConfigurationMapper on DropInConfiguration {
  DropInConfigurationDTO toDTO(
    String sdkVersionNumber,
    isPartialPaymentSupported,
  ) =>
      DropInConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode.toUpperCase(),
        amount: amount?.toDTO(),
        shopperLocale: shopperLocale,
        cardConfigurationDTO: cardConfiguration?.toDTO(),
        applePayConfigurationDTO: applePayConfiguration?.toDTO(),
        googlePayConfigurationDTO: googlePayConfiguration?.toDTO(),
        cashAppPayConfigurationDTO: cashAppPayConfiguration?.toDTO(),
        twintConfigurationDTO: twintConfiguration?.toDTO(),
        threeDS2ConfigurationDTO: threeDS2Configuration?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
        isRemoveStoredPaymentMethodEnabled: _isRemoveStoredPaymentMethodEnabled(
            storedPaymentMethodConfiguration),
        showPreselectedStoredPaymentMethod: storedPaymentMethodConfiguration
                ?.showPreselectedStoredPaymentMethod ??
            true,
        skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
        preselectedPaymentMethodTitle: preselectedPaymentMethodTitle,
        paymentMethodNames: paymentMethodNames,
        isPartialPaymentSupported: isPartialPaymentSupported,
      );

  bool _isRemoveStoredPaymentMethodEnabled(
          StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration) =>
      storedPaymentMethodConfiguration?.deleteStoredPaymentMethodCallback !=
          null &&
      storedPaymentMethodConfiguration?.isRemoveStoredPaymentMethodEnabled ==
          true;
}

extension CardConfigurationMapper on CardConfiguration {
  CardConfigurationDTO toDTO() => CardConfigurationDTO(
        holderNameRequired: holderNameRequired,
        addressMode: addressMode,
        showStorePaymentField: showStorePaymentField,
        showCvcForStoredCard: showCvcForStoredCard,
        showCvc: showCvc,
        kcpFieldVisibility: kcpFieldVisibility,
        socialSecurityNumberFieldVisibility:
            socialSecurityNumberFieldVisibility,
        supportedCardTypes: supportedCardTypes,
      );
}

extension GooglePayConfigurationMapper on GooglePayConfiguration {
  GooglePayConfigurationDTO toDTO() => GooglePayConfigurationDTO(
        googlePayEnvironment: googlePayEnvironment,
        merchantAccount: merchantAccount,
        merchantInfoDTO: merchantInfo?.toDTO(),
        totalPriceStatus: totalPriceStatus,
        allowedCardNetworks: allowedCardNetworks,
        allowedAuthMethods: allowedAuthMethods
            ?.map((allowedAuthMethod) => allowedAuthMethod.name)
            .toList(),
        allowPrepaidCards: allowPrepaidCards,
        allowCreditCards: allowCreditCards,
        billingAddressRequired: billingAddressRequired,
        billingAddressParametersDTO: billingAddressParameters?.toDTO(),
        assuranceDetailsRequired: assuranceDetailsRequired,
        emailRequired: emailRequired,
        shippingAddressRequired: shippingAddressRequired,
        shippingAddressParametersDTO: shippingAddressParameters?.toDTO(),
        existingPaymentMethodRequired: existingPaymentMethodRequired,
      );
}

extension ApplePayConfigurationMapper on ApplePayConfiguration {
  ApplePayConfigurationDTO toDTO() => ApplePayConfigurationDTO(
        merchantId: merchantId,
        merchantName: merchantName,
        allowOnboarding: allowOnboarding,
        summaryItems: applePaySummaryItems
            ?.map((applePaySummaryItem) => applePaySummaryItem.toDTO())
            .toList(),
        requiredBillingContactFields: requiredBillingContactFields
            ?.map((billingContactField) => billingContactField.name)
            .toList(),
        billingContact: billingContact?.toDTO(),
        requiredShippingContactFields: requiredShippingContactFields
            ?.map((shippingContactField) => shippingContactField.name)
            .toList(),
        shippingContact: shippingContact?.toDTO(),
        applePayShippingType: applePayShippingType,
        allowShippingContactEditing: allowShippingContactEditing,
        shippingMethods: shippingMethods
            ?.map((shippingMethod) => shippingMethod.toDTO())
            .toList(),
        applicationData: applicationData,
        supportedCountries: supportedCountries,
        merchantCapability: merchantCapability,
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
      startDate: startDate?.toIso8601String(),
      endDate: endDate?.toIso8601String());
}

extension ApplePaySummaryItemsMapper on ApplePaySummaryItem {
  ApplePaySummaryItemDTO toDTO() => ApplePaySummaryItemDTO(
        label: label,
        amount: amount.toDTO(),
        type: type,
      );
}

extension CashAppPayConfigurationMapper on CashAppPayConfiguration {
  CashAppPayConfigurationDTO toDTO() => CashAppPayConfigurationDTO(
        cashAppPayEnvironment: cashAppPayEnvironment,
        returnUrl: returnUrl,
      );
}

extension TwintConfigurationMapper on TwintConfiguration {
  TwintConfigurationDTO toDTO() => TwintConfigurationDTO(
        iosCallbackAppScheme: iosCallbackAppScheme,
        showStorePaymentField: showStorePaymentField,
      );
}

extension ThreeDS2ConfigurationMapper on ThreeDS2Configuration {
  ThreeDS2ConfigurationDTO toDTO() => ThreeDS2ConfigurationDTO(
        requestorAppURL: requestorAppURL,
        uiCustomization:
            theme?.toUICustomizationDTO(toolbarTitle: toolbarTitle) ??
                (toolbarTitle == null
                    ? null
                    : ThreeDS2UICustomizationDTO(
                        toolbarCustomization: ThreeDS2ToolbarCustomizationDTO(
                          backgroundColor: null,
                          headerText: toolbarTitle,
                          buttonText: null,
                          textColor: null,
                          textFontName: null,
                          textFontSize: null,
                        ),
                      )),
      );
}

extension Adyen3DSThemeMapper on Adyen3DSTheme {
  ThreeDS2UICustomizationDTO toUICustomizationDTO({String? toolbarTitle}) {
    String? sanitizedFontFamily(String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return value;
    }

    ThreeDS2ButtonCustomizationDTO buttonDTOFromTheme(
        Adyen3DSButtonTheme? override) {
      return ThreeDS2ButtonCustomizationDTO(
        backgroundColor:
            (override?.backgroundColor ?? primaryColor)?.toHexString(),
        textColor: (override?.textColor ?? onPrimaryColor)?.toHexString(),
        cornerRadius: (override?.cornerRadius ?? buttonCornerRadius)?.round(),
        textFontSize: (override?.fontSize ?? buttonFontSize)?.round(),
      );
    }

    final fontFamily = sanitizedFontFamily(this.fontFamily);

    return ThreeDS2UICustomizationDTO(
      labelCustomization: ThreeDS2LabelCustomizationDTO(
        textFontName: fontFamily,
        textColor: textColor?.toHexString(),
        textFontSize: labelFontSize?.round(),
        headingTextColor: headingTextColor?.toHexString(),
        headingTextFontSize: headingFontSize?.round(),
        headingTextFontName: fontFamily,
      ),
      submitButtonCustomization: buttonDTOFromTheme(submitButtonTheme),
      continueButtonCustomization: buttonDTOFromTheme(continueButtonTheme),
      nextButtonCustomization: buttonDTOFromTheme(nextButtonTheme),
      cancelButtonCustomization: buttonDTOFromTheme(cancelButtonTheme),
      resendButtonCustomization: buttonDTOFromTheme(resendButtonTheme),
      textBoxCustomization: ThreeDS2TextBoxCustomizationDTO(
        borderColor: inputBorderColor?.toHexString(),
        borderWidth: inputBorderWidth?.round(),
        cornerRadius: inputCornerRadius?.round(),
        textColor: inputTextColor?.toHexString(),
        textFontName: fontFamily,
        textFontSize: labelFontSize?.round(),
      ),
      toolbarCustomization: ThreeDS2ToolbarCustomizationDTO(
        backgroundColor: headerBackgroundColor?.toHexString(),
        headerText: toolbarTitle,
        buttonText: null,
        textColor: textColor?.toHexString(),
        textFontName: fontFamily,
        textFontSize: headingFontSize?.round(),
      ),
    );
  }
}

extension ColorToHex on Color {
  String toHexString() {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

extension SessionMapper on SessionCheckout {
  SessionDTO toDTO() {
    final encodedPaymentMethods = jsonEncode(
      paymentMethods,
      toEncodable: (value) => throw Exception("Could not encode $value"),
    );

    return SessionDTO(
      id: id,
      sessionData: sessionData,
      paymentMethodsJson: encodedPaymentMethods,
    );
  }
}

extension AmountMapper on Amount {
  AmountDTO toDTO() => AmountDTO(
        value: value,
        currency: currency,
      );
}

extension OrderResponseMapper on OrderResponseDTO {
  OrderResponse fromDTO() => OrderResponse(
        pspReference: pspReference,
        orderData: orderData,
      );
}

extension CardComponentConfigurationMapper on CardComponentConfiguration {
  CardComponentConfigurationDTO toDTO(String sdkVersionNumber) =>
      CardComponentConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount?.toDTO(),
        shopperLocale: shopperLocale,
        cardConfiguration: cardConfiguration.toDTO(),
        threeDS2ConfigurationDTO: threeDS2Configuration?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
      );
}

extension GooglePayComponentConfigurationMapper
    on GooglePayComponentConfiguration {
  InstantPaymentConfigurationDTO toDTO(
    String sdkVersionNumber,
    InstantPaymentType instantPaymentType,
  ) =>
      InstantPaymentConfigurationDTO(
        instantPaymentType: instantPaymentType,
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
        googlePayConfigurationDTO: googlePayConfiguration.toDTO(),
      );
}

extension MerchantInfoMapper on MerchantInfo {
  MerchantInfoDTO toDTO() {
    return MerchantInfoDTO(
      merchantName: merchantName,
      merchantId: merchantId,
    );
  }
}

extension BillingAddressParametersMapper on BillingAddressParameters {
  BillingAddressParametersDTO toDTO() {
    return BillingAddressParametersDTO(
      format: format,
      isPhoneNumberRequired: isPhoneNumberRequired,
    );
  }
}

extension ShippingAddressParametersMapper on ShippingAddressParameters {
  ShippingAddressParametersDTO toDTO() {
    return ShippingAddressParametersDTO(
      allowedCountryCodes: allowedCountryCodes,
      isPhoneNumberRequired: isPhoneNumberRequired,
    );
  }
}

extension ApplePayComponentConfigurationMapper
    on ApplePayComponentConfiguration {
  InstantPaymentConfigurationDTO toDTO(
    String sdkVersionNumber,
    InstantPaymentType instantPaymentType,
  ) =>
      InstantPaymentConfigurationDTO(
        instantPaymentType: instantPaymentType,
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
        applePayConfigurationDTO: applePayConfiguration.toDTO(),
      );
}

extension EncryptedCardMapper on EncryptedCardDTO {
  EncryptedCard fromDTO() => EncryptedCard(
        encryptedCardNumber: encryptedCardNumber,
        encryptedExpiryMonth: encryptedExpiryMonth,
        encryptedExpiryYear: encryptedExpiryYear,
        encryptedSecurityCode: encryptedSecurityCode,
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

extension InstantComponentConfigurationMapper on InstantComponentConfiguration {
  InstantPaymentConfigurationDTO toDTO(
    String sdkVersionNumber,
    InstantPaymentType instantPaymentType,
  ) =>
      InstantPaymentConfigurationDTO(
        instantPaymentType: instantPaymentType,
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
      );
}

extension PaymentResultModelMapper on PaymentResultModelDTO {
  ResultCode toResultCode() => ResultCode.values.firstWhere(
        (resultCodeEnum) =>
            resultCodeEnum.name.toUpperCase() == resultCode?.toUpperCase(),
        orElse: () => ResultCode.unknown,
      );
}

extension ActionComponentConfigurationMapper on ActionComponentConfiguration {
  ActionComponentConfigurationDTO toDTO(String sdkVersionNumber) =>
      ActionComponentConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        shopperLocale: shopperLocale,
        amount: amount?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
      );
}

extension OrderCancelResponseMapper on OrderCancelResult {
  OrderCancelResultDTO toDTO() => OrderCancelResultDTO(
        orderCancelResponseBody: orderCancelResponseBody,
        updatedPaymentMethodsResponseBody: updatedPaymentMethodsResponseBody,
      );
}

extension BinLookupDataMapper on Iterable<BinLookupDataDTO> {
  List<BinLookupData> toBinLookupDataList() =>
      map((entry) => BinLookupData(brand: entry.brand)).toList();
}
