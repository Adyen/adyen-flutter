import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/analytics_options.dart';

extension AnalyticsOptionsMapper on AnalyticsOptions {
  AnalyticsOptionsDTO toDTO() => AnalyticsOptionsDTO(
        enabled: enabled,
        payload: payload,
      );
}

extension DropInConfigurationMapper on DropInConfiguration {
  DropInConfigurationDTO toDTO() => DropInConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode.toUpperCase(),
        amount: amount.toDTO(),
        shopperLocale: shopperLocale ?? Platform.localeName,
        cardsConfigurationDTO: cardsConfiguration?.toDTO(),
        applePayConfigurationDTO: applePayConfiguration?.toDTO(),
        googlePayConfigurationDTO: googlePayConfiguration?.toDTO(),
        cashAppPayConfigurationDTO: cashAppPayConfiguration?.toDTO(),
        analyticsOptionsDTO: analyticsOptions?.toDTO(),
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

extension CardsConfigurationMapper on CardConfiguration {
  CardsConfigurationDTO toDTO() => CardsConfigurationDTO(
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
  CardComponentConfigurationDTO toDTO() => CardComponentConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount.toDTO(),
        shopperLocale: shopperLocale,
        cardsConfiguration: cardConfiguration.toDTO(),
      );
}
