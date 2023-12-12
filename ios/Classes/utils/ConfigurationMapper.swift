@_spi(AdyenInternal)
import Adyen
import PassKit

class ConfigurationMapper {
    func createDropInConfiguration(dropInConfigurationDTO: DropInConfigurationDTO) throws -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration(allowsSkippingPaymentList: dropInConfigurationDTO.skipListWhenSinglePaymentMethod,
                                                                allowPreselectedPaymentView: dropInConfigurationDTO.showPreselectedStoredPaymentMethod)

        dropInConfiguration.paymentMethodsList.allowDisablingStoredPaymentMethods = dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled

        if let cardConfigurationDTO = dropInConfigurationDTO.cardConfigurationDTO {
            let koreanAuthenticationMode = cardConfigurationDTO.kcpFieldVisibility.toCardFieldVisibility()
            let socialSecurityNumberMode = cardConfigurationDTO.socialSecurityNumberFieldVisibility.toCardFieldVisibility()
            let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: cardConfigurationDTO.showCvcForStoredCard)
            let allowedCardTypes = determineAllowedCardTypes(cardTypes: cardConfigurationDTO.supportedCardTypes)
            let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: cardConfigurationDTO.addressMode)
            let cardConfiguration = DropInComponent.Card(
                showsHolderNameField: cardConfigurationDTO.holderNameRequired,
                showsStorePaymentMethodField: cardConfigurationDTO.showStorePaymentField,
                showsSecurityCodeField: cardConfigurationDTO.showCvc,
                koreanAuthenticationMode: koreanAuthenticationMode,
                socialSecurityNumberMode: socialSecurityNumberMode,
                storedCardConfiguration: storedCardConfiguration,
                allowedCardTypes: allowedCardTypes,
                billingAddress: billingAddressConfiguration
            )

            dropInConfiguration.card = cardConfiguration
        }

        if let appleConfigurationDTO = dropInConfigurationDTO.applePayConfigurationDTO {
            let appleConfiguration = try buildApplePayConfiguration(applePayConfigurationDTO: appleConfigurationDTO, amount: dropInConfigurationDTO.amount, countryCode: dropInConfigurationDTO.countryCode)
            dropInConfiguration.applePay = appleConfiguration
        }

        if let cashAppPayConfigurationDTO = dropInConfigurationDTO.cashAppPayConfigurationDTO {
            dropInConfiguration.cashAppPay = DropInComponent.CashAppPay(redirectURL: URL(string: cashAppPayConfigurationDTO.returnUrl)!)
        }

        return dropInConfiguration
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

    private func buildApplePayConfiguration(applePayConfigurationDTO: ApplePayConfigurationDTO, amount: AmountDTO, countryCode: String) throws -> Adyen.ApplePayComponent.Configuration {
        // TODO: Adjust pigeon code generation to use Int instead of Int64
        guard let value = Int(exactly: amount.value) else {
            throw PlatformError(errorDescription: "Cannot map Int64 to Int.")
        }
        let currencyCode = amount.currency
        let formattedAmount = AmountFormatter.decimalAmount(value,
                                                            currencyCode: currencyCode,
                                                            localeIdentifier: nil)

        let applePayPayment = try ApplePayPayment(countryCode: countryCode,
                                                  currencyCode: currencyCode,
                                                  summaryItems: [PKPaymentSummaryItem(label: applePayConfigurationDTO.merchantName, amount: formattedAmount)])

        return ApplePayComponent.Configuration(payment: applePayPayment,
                                               merchantIdentifier: applePayConfigurationDTO.merchantId)
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
        let environment = environment.mapToEnvironment()
        let apiContext = try APIContext(environment: environment, clientKey: clientKey)
        let amount = amount.mapToAmount()
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = analyticsOptionsDTO.enabled
        analyticsConfiguration.context = TelemetryContext(version: analyticsOptionsDTO.version, platform: .flutter)
        return AdyenContext(apiContext: apiContext, payment: Payment(amount: amount, countryCode: countryCode), analyticsConfiguration: analyticsConfiguration)
    }
}

extension CardConfigurationDTO {
    func mapToCardComponentConfiguration() -> CardComponent.Configuration {
        var formComponentStyle = FormComponentStyle()
        formComponentStyle.backgroundColor = UIColor.white
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        return CardComponent.Configuration(
            style: formComponentStyle,
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
        let environment = environment.mapToEnvironment()
        let apiContext = try APIContext(environment: environment, clientKey: clientKey)
        let amount = amount.mapToAmount()
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = analyticsOptionsDTO.enabled
        analyticsConfiguration.context = TelemetryContext(version: analyticsOptionsDTO.version, platform: .flutter)
        return AdyenContext(apiContext: apiContext, payment: Payment(amount: amount, countryCode: countryCode), analyticsConfiguration: analyticsConfiguration)
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
        return Adyen.Amount(value: Int(value), currencyCode: currency)
    }
}
