import Adyen
import AdyenCard
import AdyenCheckout
import AdyenComponents
import AdyenEncryption
import Foundation
import PassKit

extension EnvironmentDTO {
    func toNativeEnvironment() -> Adyen.Environment {
        switch self {
        case .test: return .test
        case .liveEurope: return .liveEurope
        case .liveUnitedStates: return .liveUnitedStates
        case .liveAustralia: return .liveAustralia
        case .liveApse: return .liveApse
        case .liveIndia: return .liveIndia
        case .liveNea: return .liveNea
        }
    }
}

extension AmountDTO {
    func toNativeAmount() -> Adyen.Amount {
        Adyen.Amount(value: Int(value), currencyCode: currency)
    }
}

extension CheckoutConfigurationDTO {
    func toCheckoutConfiguration() throws -> AdyenCheckout.CheckoutConfiguration {
        let nativeApplePayConfiguration = try applePayConfiguration.map {
            try mapApplePayConfiguration(
                dto: $0,
                amount: $0.amount.toNativeAmount(),
                countryCode: $0.countryCode
            )
        }
        let configuration = try makeCheckoutConfiguration(
            environment: environment.toNativeEnvironment(),
            clientKey: clientKey,
            analyticsEnabled: analyticsConfiguration.enabled,
            card: cardConfiguration?.toNativeConfiguration(),
            applePay: nativeApplePayConfiguration
        )
        return configuration.showsSubmitButton(showSubmitButton)
    }
}

extension CheckoutConfigurationDTO {
    /// Apple Pay callbacks require an Apple Pay configuration, which supplies the currency code.
    func toApplePayCallbacks(
        callbacks: ApplePayCallbacksDTO?,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String
    ) -> ApplePayCallbacks? {
        guard let callbacks, let applePayConfiguration else { return nil }
        return callbacks.makeCallbacks(
            callbacksApi: callbacksApi,
            checkoutId: checkoutId,
            currencyCode: applePayConfiguration.amount.currency
        )
    }
}

private func makeCheckoutConfiguration(
    environment: Adyen.Environment,
    clientKey: String,
    analyticsEnabled: Bool,
    card: AdyenCard.CardConfiguration?,
    applePay: ApplePayConfiguration?
) throws -> AdyenCheckout.CheckoutConfiguration {
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: analyticsEnabled)
    switch (card, applePay) {
    case let (card?, applePay?):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            card
            applePay
        }
    case let (card?, nil):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            card
        }
    case let (nil, applePay?):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            applePay
        }
    case (nil, nil):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {}
    }
}

extension CardConfigurationDTO {
    func toNativeConfiguration() -> AdyenCard.CardConfiguration {
        CardConfiguration()
            .billingAddressMode(billingAddressMode.toNativeBillingAddressMode())
            .koreanAuthenticationVisibility(koreanAuthenticationVisibility.toNativeFieldVisibility())
            .showCardholderName(showCardholderName)
            .showSecurityCode(showSecurityCode)
            .showSecurityCodeForStoredCard(showSecurityCodeForStoredCard)
            .showStorePaymentMethod(showStorePaymentMethod)
            .supportedCardBrands(supportedCardBrands?.map { CardBrand(rawValue: $0) })
            .installmentConfiguration(installmentConfiguration?.toNativeConfiguration())
    }

}

extension BillingAddressModeDTO {
    func toNativeBillingAddressMode() -> AdyenCard.BillingAddressMode {
        switch self {
        case .none: return .none
        case .postalCode: return .postalCode()
        }
    }
}

extension FieldVisibilityDTO {
    func toNativeFieldVisibility() -> AdyenCard.CardConfiguration.FieldVisibility {
        switch self {
        case .show: return .show
        case .hide: return .hide
        case .auto: return .auto
        }
    }
}

extension InstallmentConfigurationDTO {
    func toNativeConfiguration() -> InstallmentConfiguration? {
        let defaultOption = options.first(where: { $0.cardBrand == nil })?.toNativeOptions()
        let cardOptions: [CardBrand: InstallmentOptions] = options.reduce(into: [:]) { result, option in
            guard let cardBrand = option.cardBrand else { return }
            result[CardBrand(rawValue: cardBrand)] = option.toNativeOptions()
        }
        guard defaultOption != nil || !cardOptions.isEmpty else { return nil }
        if let defaultOption {
            return InstallmentConfiguration(
                defaultOptions: defaultOption,
                cardBasedOptions: cardOptions.isEmpty ? nil : cardOptions,
                showInstallmentAmount: showInstallmentAmount
            )
        }
        return InstallmentConfiguration(
            cardBasedOptions: cardOptions,
            showInstallmentAmount: showInstallmentAmount
        )
    }
}

extension InstallmentOptionsDTO {
    func toNativeOptions() -> Adyen.InstallmentOptions {
        InstallmentOptions(
            values: values.map { Int($0) },
            plans: includesRevolving ? [.regular, .revolving] : [.regular]
        )
    }
}

extension UnencryptedCardDTO {
    func toCard() -> Card {
        Card(
            number: cardNumber,
            securityCode: cvc,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear
        )
    }
}

extension EncryptedCard {
    func toDTO() -> EncryptedCardDTO {
        EncryptedCardDTO(
            encryptedCardNumber: number,
            encryptedExpiryMonth: expiryMonth,
            encryptedExpiryYear: expiryYear,
            encryptedSecurityCode: securityCode
        )
    }
}
