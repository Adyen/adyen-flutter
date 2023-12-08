import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

extension AnalyticsOptionsMapper on AnalyticsOptions {
  AnalyticsOptionsDTO toDTO(String version) => AnalyticsOptionsDTO(
        enabled: enabled,
        version: version,
      );
}

extension DropInConfigurationMapper on DropInConfiguration {
  DropInConfigurationDTO toDTO(String sdkVersionNumber) =>
      DropInConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode.toUpperCase(),
        amount: amount.toDTO(),
        shopperLocale: shopperLocale ?? Platform.localeName,
        cardConfigurationDTO: cardConfiguration?.toDTO(),
        applePayConfigurationDTO: applePayConfiguration?.toDTO(),
        googlePayConfigurationDTO: googlePayConfiguration?.toDTO(),
        cashAppPayConfigurationDTO: cashAppPayConfiguration?.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
        isRemoveStoredPaymentMethodEnabled: _isRemoveStoredPaymentMethodEnabled(
            storedPaymentMethodConfiguration),
        showPreselectedStoredPaymentMethod: storedPaymentMethodConfiguration
                ?.showPreselectedStoredPaymentMethod ??
            true,
        skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
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
        merchantAccount: merchantAccount,
        allowedCardNetworks: allowedCardNetworks,
        allowedAuthMethods: allowedAuthMethods
            .map((allowedAuthMethod) => allowedAuthMethod.name)
            .toList(),
        totalPriceStatus: totalPriceStatus,
        allowPrepaidCards: allowPrepaidCards,
        billingAddressRequired: billingAddressRequired,
        emailRequired: emailRequired,
        shippingAddressRequired: shippingAddressRequired,
        existingPaymentMethodRequired: existingPaymentMethodRequired,
        googlePayEnvironment: googlePayEnvironment,
      );
}

extension ApplePayConfigurationMapper on ApplePayConfiguration {
  ApplePayConfigurationDTO toDTO() => ApplePayConfigurationDTO(
        merchantId: merchantId,
        merchantName: merchantName,
        allowOnboarding: allowOnboarding,
      );
}

extension CashAppPayConfigurationMapper on CashAppPayConfiguration {
  CashAppPayConfigurationDTO toDTO() => CashAppPayConfigurationDTO(
        cashAppPayEnvironment: cashAppPayEnvironment,
        returnUrl: returnUrl,
      );
}

extension SessionMapper on Session {
  SessionDTO toDTO() => SessionDTO(
        id: id,
        sessionData: sessionData,
        paymentMethodsJson: paymentMethodsJson,
      );
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
        amount: amount.toDTO(),
        shopperLocale: shopperLocale,
        cardConfiguration: cardConfiguration.toDTO(),
        analyticsOptionsDTO: analyticsOptions.toDTO(sdkVersionNumber),
      );
}
