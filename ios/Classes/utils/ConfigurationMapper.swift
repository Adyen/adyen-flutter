@_spi(AdyenInternal)
import Adyen
import PassKit

extension DropInConfigurationDTO {
    func createDropInConfiguration(payment: Payment?) throws -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration(
            allowsSkippingPaymentList: skipListWhenSinglePaymentMethod,
            allowPreselectedPaymentView: showPreselectedStoredPaymentMethod
        )

        dropInConfiguration.paymentMethodsList.allowDisablingStoredPaymentMethods = isRemoveStoredPaymentMethodEnabled

        if let shopperLocal = shopperLocale {
            dropInConfiguration.localizationParameters = LocalizationParameters(enforcedLocale: shopperLocal)
        }
        
        if let cardConfigurationDTO {
            dropInConfiguration.card = buildCard(from: cardConfigurationDTO)
        }

        if let applePayConfigurationDTO {
            dropInConfiguration.applePay = try applePayConfigurationDTO.toApplePayConfiguration(payment: payment)
        }

        if let cashAppPayConfigurationDTO {
            dropInConfiguration.cashAppPay = DropInComponent.CashAppPay(redirectURL: URL(string: cashAppPayConfigurationDTO.returnUrl)!)
        }

        dropInConfiguration.style = AdyenAppearanceLoader.findDropInStyle() ?? DropInComponent.Style()

        return dropInConfiguration
    }
    
    private func buildCard(from cardConfigurationDTO: CardConfigurationDTO) -> DropInComponent.Card {
        let koreanAuthenticationMode = cardConfigurationDTO.kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = cardConfigurationDTO.socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: cardConfigurationDTO.showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: cardConfigurationDTO.supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: cardConfigurationDTO.addressMode)
        return DropInComponent.Card(
            showsHolderNameField: cardConfigurationDTO.holderNameRequired,
            showsStorePaymentMethodField: cardConfigurationDTO.showStorePaymentField,
            showsSecurityCodeField: cardConfigurationDTO.showCvc,
            koreanAuthenticationMode: koreanAuthenticationMode,
            socialSecurityNumberMode: socialSecurityNumberMode,
            storedCardConfiguration: storedCardConfiguration,
            allowedCardTypes: allowedCardTypes,
            billingAddress: billingAddressConfiguration
        )
    }

    private func createStoredCardConfiguration(showCvcForStoredCard: Bool) -> StoredCardConfiguration {
        var storedCardConfiguration = StoredCardConfiguration()
        storedCardConfiguration.showsSecurityCodeField = showCvcForStoredCard
        return storedCardConfiguration
    }

    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardType]? {
        guard let mappedCardTypes = cardTypes, !mappedCardTypes.isEmpty else {
            return nil
        }

        return mappedCardTypes.compactMap { $0 }.map { CardType(rawValue: $0.lowercased()) }
    }

    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
        var billingAddressConfiguration = BillingAddressConfiguration()
        switch addressMode {
        case .full:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.full
        case .postalCode:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
        case .none:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        default:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        }

        return billingAddressConfiguration
    }

}

extension FieldVisibility {
    func toCardFieldVisibility() -> CardComponent.FieldVisibility {
        switch self {
        case .show:
            return .show
        case .hide:
            return .hide
        }
    }
}

extension DropInConfigurationDTO {
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode
        )
    }
}

extension CardConfigurationDTO {
    func mapToCardComponentConfiguration(shopperLocale: String?) -> CardComponent.Configuration {
        var formComponentStyle = AdyenAppearanceLoader.findCardComponentStyle() ?? FormComponentStyle()
        formComponentStyle.backgroundColor = UIColor.white
        let localizationParameters = shopperLocale != nil ? LocalizationParameters(enforcedLocale: shopperLocale!) : nil
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        return CardComponent.Configuration(
            style: formComponentStyle,
            localizationParameters: localizationParameters,
            showsHolderNameField: holderNameRequired,
            showsStorePaymentMethodField: showStorePaymentField,
            showsSecurityCodeField: showCvc,
            koreanAuthenticationMode: koreanAuthenticationMode,
            socialSecurityNumberMode: socialSecurityNumberMode,
            storedCardConfiguration: storedCardConfiguration,
            allowedCardTypes: allowedCardTypes,
            billingAddress: billingAddressConfiguration
        )
    }

    private func createStoredCardConfiguration(showCvcForStoredCard: Bool) -> StoredCardConfiguration {
        var storedCardConfiguration = StoredCardConfiguration()
        storedCardConfiguration.showsSecurityCodeField = showCvcForStoredCard
        return storedCardConfiguration
    }

    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardType]? {
        guard let mappedCardTypes = cardTypes, !mappedCardTypes.isEmpty else {
            return nil
        }

        return mappedCardTypes.compactMap { $0 }.map { CardType(rawValue: $0.lowercased()) }
    }

    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
        var billingAddressConfiguration = BillingAddressConfiguration()
        switch addressMode {
        case .full:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.full
        case .postalCode:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
        case .none:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        default:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        }

        return billingAddressConfiguration
    }
}

extension CardComponentConfigurationDTO {
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode
        )
    }
}

extension Environment {
    func mapToEnvironment() -> Adyen.Environment {
        switch self {
        case .test:
            return Adyen.Environment.test
        case .europe:
            return .liveEurope
        case .unitedStates:
            return .liveUnitedStates
        case .australia:
            return .liveAustralia
        case .india:
            return .liveIndia
        case .apse:
            return .liveApse
        }
    }
}

extension AmountDTO {
    func mapToAmount() -> Adyen.Amount {
        Adyen.Amount(value: Int(value), currencyCode: currency)
    }
}

extension InstantPaymentConfigurationDTO {
    func mapToApplePayConfiguration(payment: Payment?) throws -> ApplePayComponent.Configuration {
        guard let applePayConfiguration = try applePayConfigurationDTO?.toApplePayConfiguration(payment: payment) else {
            throw PlatformError(errorDescription: "Apple pay configuration not provided.")
        }
        
        return applePayConfiguration
    }
    
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode
        )
    }
}

private func buildAdyenContext(environment: Environment, clientKey: String, amount: AmountDTO?, analyticsOptionsDTO: AnalyticsOptionsDTO, countryCode: String) throws -> AdyenContext {
    let environment = environment.mapToEnvironment()
    let apiContext = try APIContext(
        environment: environment,
        clientKey: clientKey
    )
    var payment: Payment? = nil
    if let amount {
        payment = Payment(amount: amount.mapToAmount(), countryCode: countryCode)
    }
    var analyticsConfiguration = AnalyticsConfiguration()
    analyticsConfiguration.isEnabled = analyticsOptionsDTO.enabled
    analyticsConfiguration.context = AnalyticsContext(
        version: analyticsOptionsDTO.version,
        platform: .flutter
    )

    return AdyenContext(
        apiContext: apiContext,
        payment: payment,
        analyticsConfiguration: analyticsConfiguration
    )
}

extension UnencryptedCardDTO {
    func mapToUnencryptedCard() -> Card {
        Card(
            number: cardNumber,
            securityCode: cvc,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear
        )
    }
}

extension EncryptedCard {
    func mapToEncryptedCardDTO() -> EncryptedCardDTO {
        EncryptedCardDTO(
            encryptedCardNumber: number,
            encryptedExpiryMonth: expiryMonth,
            encryptedExpiryYear: expiryYear,
            encryptedSecurityCode: securityCode
        )
    }
}

extension PaymentResultEnum {
    static func from(error: Error) -> Self {
        if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
            .cancelledByUser
        } else {
            .error
        }
    }
}

extension ResultCode {
    var isAccepted: Bool {
        switch self {
        case .authorised, .received, .pending:
            return true
        case .refused, .cancelled, .error, .redirectShopper, .identifyShopper, .challengeShopper, .presentToShopper:
            return false
        }
    }
}

extension AdyenSession.Context {
    var payment: Payment? {
        guard let countryCode else { return nil }
        return Payment(amount: amount, countryCode: countryCode)
    }
}
