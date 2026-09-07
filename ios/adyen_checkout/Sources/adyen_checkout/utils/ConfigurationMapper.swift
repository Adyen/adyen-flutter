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
    func toCheckoutConfiguration(
        callbacksApi: CheckoutCallbacksFlutterApi? = nil,
        checkoutId: String? = nil
    ) throws -> AdyenCheckout.CheckoutConfiguration {
        let nativeApplePayConfiguration: ApplePayConfiguration?
        if let applePayConfiguration {
            guard let amount, let countryCode else {
                throw PlatformError(errorDescription: "Amount and countryCode are required for Apple Pay.")
            }
            nativeApplePayConfiguration = try mapApplePayConfiguration(
                dto: applePayConfiguration,
                amount: amount.toNativeAmount(),
                countryCode: countryCode,
                callbacksApi: callbacksApi,
                checkoutId: checkoutId
            )
        } else {
            nativeApplePayConfiguration = nil
        }
        let configuration = try makeCheckoutConfiguration(
            environment: environment.toNativeEnvironment(),
            amount: amount?.toNativeAmount(),
            clientKey: clientKey,
            analyticsEnabled: analyticsConfiguration.enabled,
            card: cardConfiguration?.toNativeConfiguration(),
            applePay: nativeApplePayConfiguration
        )
        return configuration.showsSubmitButton(showSubmitButton)
    }
}

private func makeCheckoutConfiguration(
    environment: Adyen.Environment,
    amount: Adyen.Amount?,
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
            amount: amount,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            card
            applePay
        }
    case let (card?, nil):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            amount: amount,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            card
        }
    case let (nil, applePay?):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            amount: amount,
            clientKey: clientKey,
            analyticsConfiguration: analyticsConfiguration
        ) {
            applePay
        }
    case (nil, nil):
        return try AdyenCheckout.CheckoutConfiguration(
            environment: environment,
            amount: amount,
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
                cardBasedOptions: cardOptions,
                defaultOptions: defaultOption,
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
            monthValues: values.map { UInt($0) },
            includesRevolving: includesRevolving
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
