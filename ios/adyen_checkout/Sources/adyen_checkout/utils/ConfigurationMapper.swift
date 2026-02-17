@_spi(AdyenInternal) import Adyen
import PassKit
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenEncryption)
    import AdyenEncryption
#endif
#if canImport(Adyen3DS2)
    import Adyen3DS2
#endif
#if canImport(AdyenActions)
    import AdyenActions
#endif

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

        if let twintConfigurationDTO {
            dropInConfiguration.actionComponent.twint = .init(callbackAppScheme: twintConfigurationDTO.iosCallbackAppScheme)
        }

        if let threeDS2ConfigurationDTO {
            dropInConfiguration.actionComponent.threeDS = threeDS2ConfigurationDTO.mapToThreeDS2Configuration()
        }

        dropInConfiguration.style = AdyenAppearance.dropInStyle

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

extension ThreeDS2SelectionItemCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        if let selectionIndicatorTintColor,
           let tintColor = UIColor(hex: selectionIndicatorTintColor) {
            //THis is wrong, map it to selectAppearance
            configuration.switchAppearance.switchTintColor = tintColor
        }
    }
}

extension DropInConfigurationDTO {
    func createAdyenContext(payment: Payment? = nil) throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode,
            payment: payment
        )
    }
}

extension CardConfigurationDTO {
    func mapToCardComponentConfiguration(shopperLocale: String?) -> CardComponent.Configuration {
        let cardComponentStyle = AdyenAppearance.cardComponentStyle
        let localizationParameters = shopperLocale != nil ? LocalizationParameters(enforcedLocale: shopperLocale!) : nil
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        return CardComponent.Configuration(
            style: cardComponentStyle,
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

    func createAdyenContext(payment: Payment? = nil) throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode,
            payment: payment
        )
    }
}

private func buildAdyenContext(environment: Environment, clientKey: String, amount: AmountDTO?, analyticsOptionsDTO: AnalyticsOptionsDTO, countryCode: String?, payment: Payment? = nil) throws -> AdyenContext {
    let environment = environment.mapToEnvironment()
    let apiContext = try APIContext(
        environment: environment,
        clientKey: clientKey
    )
    let payment: Payment? = payment ?? {
        if let amount, let countryCode {
            return Payment(amount: amount.mapToAmount(), countryCode: countryCode)
        }
        return nil
    }()
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
        } else if isThree3ds2Cancellation(error: error as NSError) {
            .cancelledByUser
        } else {
            .error
        }
    }
    
    private static func isThree3ds2Cancellation(error: NSError) -> Bool {
        error.domain == ADYRuntimeErrorDomain && error.code == ADYRuntimeErrorCode.challengeCancelled.rawValue
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
    func createPayment(fallbackCountryCode: String) -> Payment {
        Payment(amount: amount, countryCode: countryCode ?? fallbackCountryCode)
    }
}

extension ActionComponentConfigurationDTO {
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: nil,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: nil
        )
    }
}

extension ThreeDS2ConfigurationDTO {
    func mapToThreeDS2Configuration() -> AdyenActionComponent.Configuration.ThreeDS {
        let appearanceConfiguration = uiCustomization?.toAppearanceConfiguration() ?? ADYAppearanceConfiguration()
        guard let requestorAppURL, let url = URL(string: requestorAppURL) else {
            return .init(appearanceConfiguration: appearanceConfiguration)
        }
        return .init(requestorAppURL: url, appearanceConfiguration: appearanceConfiguration)
    }
}

extension ThreeDS2UICustomizationDTO {
    func toAppearanceConfiguration() -> ADYAppearanceConfiguration {
        let configuration = ADYAppearanceConfiguration()

        if let screenCustomization {
            screenCustomization.apply(to: configuration)
        }
        
        if let headingCustomization {
            headingCustomization.apply(to: configuration)
        }

        if let labelCustomization {
            labelCustomization.apply(to: configuration)
        }

        if let inputCustomization {
            inputCustomization.apply(to: configuration)
        }

        if let selectionItemCustomization {
            selectionItemCustomization.apply(to: configuration)
        }

        // Primary group: submit / continue / next / OOB
        primaryButtonCustomization?.apply(to: configuration, buttonType: .submit)
        primaryButtonCustomization?.apply(to: configuration, buttonType: .continue)
        primaryButtonCustomization?.apply(to: configuration, buttonType: .next)
        primaryButtonCustomization?.apply(to: configuration, buttonType: .OOB)

        // Secondary group: cancel / resend
        secondaryButtonCustomization?.apply(to: configuration, buttonType: .cancel)
        secondaryButtonCustomization?.apply(to: configuration, buttonType: .resend)

        return configuration
    }
}

extension ThreeDS2ScreenCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        // Apply screen background color
        if let backgroundColor, let bgColor = UIColor(hex: backgroundColor) {
            configuration.backgroundColor = bgColor
        }
        
        // Apply general text styling as fallback for labels
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            configuration.textColor = textUIColor
            configuration.tintColor = textUIColor
            configuration.infoAppearance.headingTextColor = textUIColor
            configuration.infoAppearance.textColor = textUIColor
        }
        
    }
}

extension ThreeDS2ToolbarCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        if let backgroundColor, let backgroundColor = UIColor(hex: backgroundColor) {
            configuration.navigationBarAppearance.backgroundColor = backgroundColor
        }
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            configuration.navigationBarAppearance.textColor = textUIColor
        }
        if let headerText {
            configuration.navigationBarAppearance.title = headerText
        }
    }
}

extension ThreeDS2LabelCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        if let headingTextColor, let headingColor = UIColor(hex: headingTextColor) {
            configuration.labelAppearance.headingTextColor = headingColor
        }
        if let headingTextFontSize {
            configuration.labelAppearance.headingFont = configuration.labelAppearance.headingFont.withSize(CGFloat(headingTextFontSize))
        }
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            configuration.labelAppearance.textColor = textUIColor
        }
        if let textFontSize {
            configuration.labelAppearance.font = configuration.labelAppearance.font.withSize(CGFloat(textFontSize))
        }
        if let inputLabelTextColor, let inputLabelColor = UIColor(hex: inputLabelTextColor) {
            configuration.labelAppearance.subheadingTextColor = inputLabelColor
        }
        if let inputLabelFontSize {
            configuration.labelAppearance.subheadingFont = configuration.labelAppearance.subheadingFont.withSize(CGFloat(inputLabelFontSize))
        }
    }
}

extension ThreeDS2InputCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        if let borderColor, let boarderUIColor = UIColor(hex: borderColor) {
            configuration.textFieldAppearance.borderColor = boarderUIColor
        }
        if let borderWidth {
            configuration.textFieldAppearance.borderWidth = CGFloat(borderWidth)
        }
        if let cornerRadius {
            configuration.textFieldAppearance.cornerRadius = CGFloat(cornerRadius)
        }
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            configuration.textFieldAppearance.textColor = textUIColor
        }
    }
}

extension ThreeDS2ButtonCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration, buttonType: ADYAppearanceButtonType) {
        let buttonAppearance = configuration.buttonAppearance(for: buttonType)

        if let backgroundColor, let buttonColor = UIColor(hex: backgroundColor) {
            buttonAppearance.backgroundColor = buttonColor
        }
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            buttonAppearance.textColor = textUIColor
        }
        if let cornerRadius {
            buttonAppearance.cornerRadius = CGFloat(cornerRadius)
        }
        if let textFontSize {
            buttonAppearance.font = buttonAppearance.font.withSize(CGFloat(textFontSize))
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red, green, blue, alpha: CGFloat
        if hexSanitized.count == 8 {
            alpha = CGFloat((rgb & 0xFF00_0000) >> 24) / 255.0
            red = CGFloat((rgb & 0x00FF_0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x0000_FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000_00FF) / 255.0
        } else if hexSanitized.count == 6 {
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
            alpha = 1.0
        } else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
