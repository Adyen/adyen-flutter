import PassKit
@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

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
    func createDropInConfiguration() throws -> DropInComponent.Configuration {
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
            dropInConfiguration.applePay = try applePayConfigurationDTO.toApplePayConfiguration(amount: amount?.mapToAmount(), countryCode: countryCode)
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

    func createCheckoutConfiguration() throws -> CheckoutConfiguration {
        return try CheckoutConfiguration(
            environment: environment.mapToEnvironment(),
            amount: amount!.mapToAmount(),
            clientKey: clientKey,
            analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled),
            content: {

            }
        )
    }

    private func buildCard(from cardConfigurationDTO: CardConfigurationDTO) -> DropInComponent.Card {
        let koreanAuthenticationMode = cardConfigurationDTO.kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = cardConfigurationDTO.socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: cardConfigurationDTO.showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: cardConfigurationDTO.supportedCardTypes)
//        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: cardConfigurationDTO.addressMode)
        let installmentConfiguration = cardConfigurationDTO.installmentConfiguration?.mapToInstallmentConfiguration()
        return DropInComponent.Card(
            showsHolderNameField: cardConfigurationDTO.holderNameRequired,
            showsStorePaymentMethodField: cardConfigurationDTO.showStorePaymentField,
            showsSecurityCodeField: cardConfigurationDTO.showCvc,
            koreanAuthenticationMode: koreanAuthenticationMode,
            socialSecurityNumberMode: socialSecurityNumberMode,
            storedCardConfiguration: storedCardConfiguration,
            allowedCardTypes: allowedCardTypes,
            installmentConfiguration: installmentConfiguration,
            //billingAddress: billingAddressConfiguration
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

//    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
//        var billingAddressConfiguration = BillingAddressConfiguration()
//        switch addressMode {
//        case .full:
//            billingAddressConfiguration.mode = CardComponent.AddressFormType.full
//        case .postalCode:
//            billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
//        case .none:
//            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
//        default:
//            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
//        }
//
//        return billingAddressConfiguration
//    }
}

extension FieldVisibility {
    func toCardFieldVisibility() -> CardComponentConfiguration.FieldVisibility {
        switch self {
        case .show:
            return .show
        case .hide:
            return .hide
        }
    }
}

extension DropInConfigurationDTO {
    // TODO: - buildAdyenContext is no longer usable in v6 (AdyenContext init is package-access).
    // Drop-in flow should be migrated to use Checkout.setup() pattern.
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
    func mapToCardComponentConfiguration(shopperLocale: String?) -> CardComponentConfiguration {
        let localizationParameters = shopperLocale != nil ? LocalizationParameters(enforcedLocale: shopperLocale!) : nil
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        let installmentConfiguration = installmentConfiguration?.mapToInstallmentConfiguration()
        return CardComponentConfiguration()
            .showsHolderNameField(holderNameRequired)
            .showsStorePaymentMethodField(showStorePaymentField)
            .showsSecurityCodeField(showCvc)
            .koreanAuthenticationMode(koreanAuthenticationMode)
            .socialSecurityNumberMode(socialSecurityNumberMode)
            .allowedCardTypes(allowedCardTypes)
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

    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressMode {
        switch addressMode {
        case .full:
            return BillingAddressMode.full
        case .postalCode:
            return BillingAddressMode.postalCode
        case .none?:
            return BillingAddressMode.none
        default:
            return BillingAddressMode.none
        }
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

    func createCardComponentConfiguration() -> CardComponentConfiguration? {
        cardConfiguration.mapToCardComponentConfiguration(shopperLocale: shopperLocale)
    }
}

extension BlikComponentConfigurationDTO {
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode
        )
    }

    func mapToBlikComponentConfiguration() -> BLIKComponentConfiguration {
        let localizationParameters = shopperLocale.map { LocalizationParameters(enforcedLocale: $0) }
        return BLIKComponentConfiguration(
            style: AdyenAppearance.blikComponentStyle,
            localizationParameters: localizationParameters
        )
    }
}

extension Environment {
    func mapToEnvironment() -> Adyen.Environment {
        switch self {
        case .test:
            return Adyen.Environment.test
        case .liveEurope:
            return .liveEurope
        case .liveUnitedStates:
            return .liveUnitedStates
        case .liveAustralia:
            return .liveAustralia
        case .liveIndia:
            return .liveIndia
        case .liveApse:
            return .liveApse
        case .liveNea:
            return .liveNea
        }
    }
}

extension AmountDTO {
    func mapToAmount() -> Adyen.Amount {
        Adyen.Amount(value: Int(value), currencyCode: currency)
    }
}

extension InstantPaymentConfigurationDTO {
    // TODO: - Payment type removed in v6. Apple Pay configuration needs migration.
    func mapToApplePayConfiguration() throws -> ApplePayComponent.Configuration {
        guard let applePayConfiguration = try applePayConfigurationDTO?.toApplePayConfiguration(amount: amount?.mapToAmount(), countryCode: countryCode) else {
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

// TODO: - AdyenContext init is now package-access in v6 SDK.
// This function is kept for compilation but will fail at runtime.
// All flows should migrate to use Checkout.setup() which creates AdyenContext internally.
private func buildAdyenContext(environment: Environment, clientKey: String, amount: AmountDTO?, analyticsOptionsDTO: AnalyticsOptionsDTO, countryCode: String?) throws -> AdyenContext {
    throw PlatformError(errorDescription: "buildAdyenContext is not supported in iOS SDK v6. Use Checkout.setup() instead.")
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

// TODO: - Payment type removed in v6 SDK. Session.State.createPayment needs migration.
//extension Session.State {
//    func createPayment(fallbackCountryCode: String) -> Payment {
//        Payment(amount: amount, countryCode: countryCode ?? fallbackCountryCode)
//    }
//}

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
    // TODO: - ThreeDS2ActionConfiguration init changed in v6. appearanceConfiguration is now package-access.
    // UI customization may need a different approach in v6.
    func mapToThreeDS2Configuration() -> ThreeDS2ActionConfiguration {
        var config = ThreeDS2ActionConfiguration()
        if let requestorAppURL, let url = URL(string: requestorAppURL) {
            config = config.requestorAppURL(url)
        }
        return config
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
        primaryButtonCustomization?.apply(to: configuration, buttonType: .submit)
        primaryButtonCustomization?.apply(to: configuration, buttonType: .continue)
        primaryButtonCustomization?.apply(to: configuration, buttonType: .next)
        secondaryButtonCustomization?.apply(to: configuration, buttonType: .cancel)
        secondaryButtonCustomization?.apply(to: configuration, buttonType: .resend)
        secondaryButtonCustomization?.apply(to: configuration, buttonType: .OOB)
        return configuration
    }
}

extension ThreeDS2ScreenCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
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
        if let cancelButtonColor, let cancelTextColor = UIColor(hex: cancelButtonColor) {
            configuration.buttonAppearance(for: .cancel).textColor = cancelTextColor
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

extension ThreeDS2SelectionItemCustomizationDTO {
    func apply(to configuration: ADYAppearanceConfiguration) {
        if let selectionIndicatorTintColor,
           let tintColor = UIColor(hex: selectionIndicatorTintColor) {
            configuration.selectAppearance.selectionIndicatorTintColor = tintColor
        }
        if let highlightedBackgroundColor, let backgroundColor = UIColor(hex: highlightedBackgroundColor) {
            configuration.selectAppearance.highlightedBackgroundColor = backgroundColor
        }
        if let textColor, let textUIColor = UIColor(hex: textColor) {
            configuration.selectAppearance.textColor = textUIColor
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

extension InstallmentConfigurationDTO {
    func mapToInstallmentConfiguration() -> InstallmentConfiguration? {
        guard defaultOptions != nil || cardBasedOptions != nil else { return nil }
        let cardBasedOptions = cardBasedOptions.flatMap { buildCardBasedInstallmentOptions(from: $0) }
        let defaultOptions = defaultOptions.map { buildDefaultInstallmentOptions(from: $0) }

        switch (defaultOptions, cardBasedOptions) {
        case let (defaultOptions?, cardBasedOptions?):
            return InstallmentConfiguration(
                cardBasedOptions: cardBasedOptions,
                defaultOptions: defaultOptions,
                showInstallmentAmount: showInstallmentAmount
            )

        case (nil, let cardBasedOptions?):
            return InstallmentConfiguration(
                cardBasedOptions: cardBasedOptions,
                showInstallmentAmount: showInstallmentAmount
            )

        case (let defaultOptions?, nil):
            return InstallmentConfiguration(
                defaultOptions: defaultOptions,
                showInstallmentAmount: showInstallmentAmount
            )

        default:
            return nil
        }
    }

    private func buildCardBasedInstallmentOptions(from cardBasedOptions: [CardBasedInstallmentOptionsDTO?]) -> [CardType: InstallmentOptions]? {
        var options: [CardType: InstallmentOptions] = [:]
        for cardBasedOption in cardBasedOptions {
            guard let cardBasedOption else { continue }
            let cardBrandRaw = cardBasedOption.cardBrand
            let cardType = CardType(rawValue: cardBrandRaw)
            options[cardType] = createInstallmentOptions(
                values: cardBasedOption.values,
                includesRevolving: cardBasedOption.includesRevolving
            )
        }
        return options.isEmpty ? nil : options
    }

    private func buildDefaultInstallmentOptions(from defaultOptions: DefaultInstallmentOptionsDTO) -> InstallmentOptions {
        createInstallmentOptions(
            values: defaultOptions.values,
            includesRevolving: defaultOptions.includesRevolving
        )
    }

    private func createInstallmentOptions(values: [Int64?], includesRevolving: Bool) -> InstallmentOptions {
        InstallmentOptions(
            monthValues: values.compactMap { $0 }.map { UInt($0) },
            includesRevolving: includesRevolving
        )
    }
}

extension SessionResponseDTO {
    func mapToSessionResponse() -> SessionResponse {
        return SessionResponse(id: id, sessionData: sessionData)
    }
}
