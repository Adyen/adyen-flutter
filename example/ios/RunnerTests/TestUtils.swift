@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
@_spi(AdyenInternal) import AdyenNetworking

#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenEncryption)
    import AdyenEncryption
#endif
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(Adyen3DS2)
    import Adyen3DS2
#endif

extension CardComponent.AddressFormType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.full, .full):
            return true
        case (.none, .none):
            return true
        case (.postalCode, .postalCode):
            return true
        default:
            return false
        }
    }
}

let testClientKey = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

func createDropInConfigurationDTO(
    environment: adyen_checkout.Environment = adyen_checkout.Environment.test,
    clientKey: String = testClientKey,
    countryCode: String = "NL",
    amount: AmountDTO? = AmountDTO(currency: "EUR", value: 1000),
    shopperLocale: String? = nil,
    cardConfigurationDTO: CardConfigurationDTO? = nil,
    applePayConfigurationDTO: ApplePayConfigurationDTO? = nil,
    cashAppPayConfigurationDTO: CashAppPayConfigurationDTO? = nil,
    twintConfigurationDTO: TwintConfigurationDTO? = nil,
    threeDS2ConfigurationDTO: ThreeDS2ConfigurationDTO? = nil,
    analyticsOptionsDTO: AnalyticsOptionsDTO = AnalyticsOptionsDTO(enabled: true, version: "1.0.0"),
    showPreselectedStoredPaymentMethod: Bool = true,
    skipListWhenSinglePaymentMethod: Bool = false,
    isRemoveStoredPaymentMethodEnabled: Bool = false
) -> DropInConfigurationDTO {
    DropInConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        countryCode: countryCode,
        amount: amount,
        shopperLocale: shopperLocale,
        cardConfigurationDTO: cardConfigurationDTO,
        applePayConfigurationDTO: applePayConfigurationDTO,
        googlePayConfigurationDTO: nil,
        cashAppPayConfigurationDTO: cashAppPayConfigurationDTO,
        twintConfigurationDTO: twintConfigurationDTO,
        threeDS2ConfigurationDTO: threeDS2ConfigurationDTO,
        analyticsOptionsDTO: analyticsOptionsDTO,
        showPreselectedStoredPaymentMethod: showPreselectedStoredPaymentMethod,
        skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
        isRemoveStoredPaymentMethodEnabled: isRemoveStoredPaymentMethodEnabled,
        preselectedPaymentMethodTitle: nil,
        paymentMethodNames: nil,
        isPartialPaymentSupported: false
    )
}

func createCardConfigurationDTO(
    holderNameRequired: Bool = false,
    addressMode: AddressMode = .none,
    showStorePaymentField: Bool = false,
    showCvcForStoredCard: Bool = true,
    showCvc: Bool = true,
    kcpFieldVisibility: FieldVisibility = .hide,
    socialSecurityNumberFieldVisibility: FieldVisibility = .hide,
    supportedCardTypes: [String?] = []
) -> CardConfigurationDTO {
    CardConfigurationDTO(
        holderNameRequired: holderNameRequired,
        addressMode: addressMode,
        showStorePaymentField: showStorePaymentField,
        showCvcForStoredCard: showCvcForStoredCard,
        showCvc: showCvc,
        kcpFieldVisibility: kcpFieldVisibility,
        socialSecurityNumberFieldVisibility: socialSecurityNumberFieldVisibility,
        supportedCardTypes: supportedCardTypes
    )
}

func createActionComponentConfigurationDTO(
    environment: adyen_checkout.Environment = adyen_checkout.Environment.test,
    clientKey: String = testClientKey,
    shopperLocale: String? = nil,
    amount: AmountDTO? = nil,
    analyticsOptionsDTO: AnalyticsOptionsDTO = AnalyticsOptionsDTO(enabled: true, version: "1.0.0")
) -> ActionComponentConfigurationDTO {
    ActionComponentConfigurationDTO(
        environment: environment,
        clientKey: clientKey,
        shopperLocale: shopperLocale,
        amount: amount,
        analyticsOptionsDTO: analyticsOptionsDTO
    )
}
