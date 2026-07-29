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

// TODO: v6 migration - DropInComponent.Configuration and related types are now package-access.
// Drop-in needs to be migrated to use Checkout.setup() pattern when Drop-in is exposed in v6 public API.
extension DropInConfigurationDTO {
    func createCheckoutConfiguration() throws -> CheckoutConfiguration {
        let cardConfig = cardConfigurationDTO?.mapToCardConfiguration(shopperLocale: shopperLocale) ?? CardConfiguration()
        let authConfig = threeDS2ConfigurationDTO?.mapToAuthenticationConfiguration() ?? AuthenticationConfiguration()
        return try CheckoutConfiguration(
            environment: environment.mapToEnvironment(),
            amount: amount!.mapToAmount(),
            clientKey: clientKey,
            analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled)
        ) {
            cardConfig
            authConfig
        }
    }
}

extension CheckoutConfigurationDTO {
    func createCheckoutConfiguration(
        componentFlutterApi: ComponentFlutterInterface? = nil,
        checkoutHolder: CheckoutHolder? = nil,
        componentPlatformEventHandler: ComponentPlatformEventHandler? = nil,
        componentId: String? = nil
    ) throws -> CheckoutConfiguration {
        let cardConfig = cardConfigurationDTO?.mapToCardConfiguration(
            shopperLocale: shopperLocale,
            componentPlatformEventHandler: componentPlatformEventHandler,
            componentId: componentId
        ) ?? CardConfiguration()
        let mappedAmount = amount?.mapToAmount()
        guard let applePayConfigurationDTO else {
            return try CheckoutConfiguration(
                environment: environment.mapToEnvironment(),
                amount: amount!.mapToAmount(),
                clientKey: clientKey,
                analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled)
            ) {
                cardConfig
            }
        }
        let applePayConfiguration = try applePayConfigurationDTO.toApplePayConfiguration(
            amount: mappedAmount,
            countryCode: countryCode,
            componentFlutterApi: componentFlutterApi,
            componentId: checkoutHolder.map { holder in
                { [weak holder] in holder?.activeApplePayComponentId ?? InstantComponentManager.Constants.applePaySessionComponentId }
            }
        )
        return try CheckoutConfiguration(
            environment: environment.mapToEnvironment(),
            amount: amount!.mapToAmount(),
            clientKey: clientKey,
            analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled)
        ) {
            cardConfig
            applePayConfiguration
        }
    }
}

extension FieldVisibility {
    func toCardFieldVisibility() -> CardConfiguration.FieldVisibility {
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
    /// - Parameters:
    ///   - componentPlatformEventHandler: When provided (together with `componentId`), bin
    ///     lookup/change events are forwarded to Flutter as `ComponentCommunicationModel`
    ///     events, the same channel already used for resize/result events. These callbacks
    ///     only ever fire while the active component is a card component, so it's safe to
    ///     always register them regardless of which payment method is actually rendered.
    ///   - componentId: The fixed componentId of the generic session/advanced component
    ///     (`"SESSION_ADYEN_COMPONENT"`/`"ADVANCED_ADYEN_COMPONENT"`), since this
    ///     configuration is attached once at `Checkout.setup()` time, before any specific
    ///     component is created.
    func mapToCardConfiguration(
        shopperLocale: String?,
        componentPlatformEventHandler: ComponentPlatformEventHandler? = nil,
        componentId: String? = nil
    ) -> CardConfiguration {
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressMode = determineBillingAddressConfiguration(addressMode: addressMode)
        let installmentConfig = installmentConfiguration?.mapToInstallmentConfiguration()
        var cardConfiguration = CardConfiguration()
            .showCardholderName(holderNameRequired)
            .showStorePaymentMethod(showStorePaymentField)
            .showSecurityCode(showCvc)
            .showSecurityCodeForStoredCard(showCvcForStoredCard)
            .koreanAuthenticationVisibility(koreanAuthenticationMode)
            .socialSecurityNumberVisibility(socialSecurityNumberMode)
            .supportedCardBrands(allowedCardTypes)
            .installmentConfiguration(installmentConfig)
            .billingAddressMode(billingAddressMode)

        if let componentPlatformEventHandler, let componentId {
            cardConfiguration = cardConfiguration
                .onBinLookup { data in
                    let binLookupDataDtoList = data.brands.map { BinLookupDataDTO(brand: $0.brand) }
                    componentPlatformEventHandler.send(event: ComponentCommunicationModel(
                        type: .binLookup,
                        componentId: componentId,
                        data: binLookupDataDtoList
                    ))
                }
                .onBinChange { binValue in
                    componentPlatformEventHandler.send(event: ComponentCommunicationModel(
                        type: .binValue,
                        componentId: componentId,
                        data: binValue
                    ))
                }
        }

        return cardConfiguration
    }

    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardBrand]? {
        guard let mappedCardTypes = cardTypes, !mappedCardTypes.isEmpty else {
            return nil
        }

        return mappedCardTypes.compactMap { $0 }.map { CardBrand(rawValue: $0.lowercased()) }
    }

    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressMode {
        switch addressMode {
        case .full:
            return BillingAddressMode.full()
        case .postalCode:
            return BillingAddressMode.postalCode()
        case .none?:
            return BillingAddressMode.none
        default:
            return BillingAddressMode.none
        }
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

    // TODO: v6 migration - BLIKComponentConfiguration is now package-access.
    // BLIK component needs to be created via Checkout.setup() + createPaymentComponent(for: .blik).
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
    func createAdyenContext() throws -> AdyenContext {
        try buildAdyenContext(
            environment: environment,
            clientKey: clientKey,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO,
            countryCode: countryCode
        )
    }

    func createCheckoutConfiguration(
        componentFlutterApi: ComponentFlutterInterface? = nil,
        componentId: (() -> String)? = nil
    ) throws -> CheckoutConfiguration {
        guard let amount else {
            throw PlatformError(errorDescription: "Amount is required to set up Apple Pay.")
        }
        let mappedAmount = amount.mapToAmount()
        guard let applePayConfigurationDTO else {
            return try CheckoutConfiguration(
                environment: environment.mapToEnvironment(),
                amount: mappedAmount,
                clientKey: clientKey,
                analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled)
            ) {}
        }
        let applePayConfiguration = try applePayConfigurationDTO.toApplePayConfiguration(
            amount: mappedAmount,
            countryCode: countryCode,
            componentFlutterApi: componentFlutterApi,
            componentId: componentId
        )
        return try CheckoutConfiguration(
            environment: environment.mapToEnvironment(),
            amount: mappedAmount,
            clientKey: clientKey,
            analyticsConfiguration: AnalyticsConfiguration(isEnabled: analyticsOptionsDTO.enabled)
        ) {
            applePayConfiguration
        }
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
        if let checkoutError = (error as? CheckoutError), checkoutError.code == CheckoutError.Code.cancelled {
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

// TODO: v6 migration - ResultCode removed from SDK. Use CheckoutResultCode instead.
// Session.State.createPayment also removed.

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
    func mapToAuthenticationConfiguration() -> AuthenticationConfiguration {
        var config = AuthenticationConfiguration()
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

    private func buildCardBasedInstallmentOptions(from cardBasedOptions: [CardBasedInstallmentOptionsDTO?]) -> [CardBrand: InstallmentOptions]? {
        var options: [CardBrand: InstallmentOptions] = [:]
        for cardBasedOption in cardBasedOptions {
            guard let cardBasedOption else { continue }
            let cardBrandRaw = cardBasedOption.cardBrand
            let cardType = CardBrand(rawValue: cardBrandRaw)
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
