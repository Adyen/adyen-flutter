import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

extension ApplePayConfigurationDTO {
    var hasAnyApplePayUpdateCallback: Bool {
        hasOnShippingMethodChange || hasOnShippingContactChange || hasOnCouponCodeChange
    }

    var hasAnyApplePayCallback: Bool {
        hasAnyApplePayUpdateCallback || hasOnAuthorize
    }
}

extension ApplePayConfigurationDTO {
    func toApplePayConfiguration(
        payment: Payment?,
        componentFlutterApi: ComponentFlutterInterface? = nil,
        componentId: String? = nil
    ) throws -> ApplePayComponent.Configuration {
        guard let payment else {
            throw AdyenPigeonError(
                code: ApplePayConfigurationErrorCode.missingAmount,
                message: "Amount for Apple Pay not provided.",
                details: nil
            )
        }
        let summaryItems = try mapToPaymentSummaryItems(summaryItems: summaryItems, payment: payment)
        let paymentRequest = try buildPaymentRequest(payment: payment, summaryItems: summaryItems)
        do {
            return try ApplePayComponent.Configuration(paymentRequest: paymentRequest, allowOnboarding: allowOnboarding ?? false)
        } catch {
            throw AdyenPigeonError(
                code: ApplePayConfigurationErrorCode.invalidConfiguration,
                message: error.localizedDescription,
                details: String(describing: error)
            )
        }
    }
    
    private func buildPaymentRequest(payment: Payment, summaryItems: [PKPaymentSummaryItem]) throws -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.paymentSummaryItems = summaryItems
        paymentRequest.countryCode = payment.countryCode
        paymentRequest.currencyCode = payment.amount.currencyCode
        paymentRequest.billingContact = billingContact?.toApplePayContact()
        paymentRequest.shippingContact = shippingContact?.toApplePayContact()
        paymentRequest.merchantCapabilities = merchantCapability.toMerchantCapability()
        if let requiredShippingContactFields {
            paymentRequest.requiredShippingContactFields = mapToContactFields(contactFields: requiredShippingContactFields)
        }

        if let requiredBillingContactFields {
            paymentRequest.requiredBillingContactFields = mapToContactFields(contactFields: requiredBillingContactFields)
        }

        if let applePayShippingType {
            paymentRequest.shippingType = applePayShippingType.toPKShippingType()
        }

        if let supportedCountries {
            paymentRequest.supportedCountries = .init(supportedCountries.compactMap { $0 })
        }

        if let shippingMethods {
            paymentRequest.shippingMethods = try shippingMethods.compactMap { try $0?.toPKShippingMethod() }
        }
        
        if #available(iOS 15.0, *) {
            allowShippingContactEditing.map {
                // We have to use enabled until we forcing the newest Xcode version. Otherwise the build fails.
                paymentRequest.shippingContactEditingMode = $0 ? PKShippingContactEditingMode.enabled : PKShippingContactEditingMode.storePickup
            }
            supportsCouponCode.map { paymentRequest.supportsCouponCode = $0 }
            couponCode.map { paymentRequest.couponCode = $0 }
        }

        if #available(iOS 16.0, *) {
            paymentRequest.recurringPaymentRequest = try recurringPaymentRequest?.toPKRecurringPaymentRequest()
            paymentRequest.automaticReloadPaymentRequest = try automaticReloadPaymentRequest?.toPKAutomaticReloadPaymentRequest()
            if let multiTokenContexts {
                paymentRequest.multiTokenContexts = try multiTokenContexts.compactMap { try $0?.toPKPaymentTokenContext() }
            }
        }

        if #available(iOS 16.4, *) {
            paymentRequest.deferredPaymentRequest = try deferredPaymentRequest?.toPKDeferredPaymentRequest()
        }
        
        applicationData.map { paymentRequest.applicationData = Data($0.utf8) }
        return paymentRequest
    }
    
    // TODO: could be deleted when implementing advanced flow
    private func addShippingMethodToSummaryItems(paymentRequest: PKPaymentRequest) {
        guard let shippingMethod = paymentRequest.shippingMethods?.first else {
            return
        }
        
        if let last = paymentRequest.paymentSummaryItems.last {
            paymentRequest.paymentSummaryItems = paymentRequest.paymentSummaryItems.dropLast()
            paymentRequest.paymentSummaryItems.append(shippingMethod)
            paymentRequest.paymentSummaryItems.append(
                .init(
                    label: last.label,
                    amount: NSDecimalNumber(
                        value: last.amount.floatValue + shippingMethod.amount.floatValue
                    )
                )
            )
        }
    }
    
    private func mapToContactFields(contactFields: [String?]) -> Set<PKContactField> {
        let contactFieldsNonNil: [String] = contactFields.compactMap { $0 }
        return Set<PKContactField>(contactFieldsNonNil.compactMap { PKContactField.fromString($0) })
    }
    
    private func mapToPaymentSummaryItems(summaryItems: [ApplePaySummaryItemDTO?]?, payment: Payment) throws -> [PKPaymentSummaryItem] {
        guard let summaryItems else {
            let formattedAmount = AmountFormatter.decimalAmount(
                payment.amount.value,
                currencyCode: payment.amount.currencyCode,
                localeIdentifier: payment.amount.localeIdentifier
            )
            return [PKPaymentSummaryItem(label: merchantName, amount: formattedAmount)]
        }
        
        let summaryItemsNonNil: [ApplePaySummaryItemDTO] = summaryItems.compactMap { $0 }
        return try summaryItemsNonNil.compactMap { try $0.toApplePaySummeryItem() }
    }
}

extension PKPaymentNetwork {
    internal var txVariantName: String {
        if self == .masterCard { return "mc" }
        if self == .cartesBancaires { return "cartebancaire" }
        return self.rawValue.lowercased()
    }
}

extension ApplePaySummaryItemDTO {
    func toApplePaySummeryItem() throws -> PKPaymentSummaryItem {
        let formattedAmount = try amount.toFormattedAmount()
        return PKPaymentSummaryItem(
            label: label,
            amount: formattedAmount,
            type: type.toPKPaymentSummaryItemType()
        )
    }
}

extension ApplePaySummaryItemType {
    func toPKPaymentSummaryItemType() -> PKPaymentSummaryItemType {
        switch self {
        case .pending:
            return PKPaymentSummaryItemType.pending
        case .definite:
            return PKPaymentSummaryItemType.final
        }
    }
}

extension ApplePayMerchantCapability? {
    func toMerchantCapability() -> PKMerchantCapability {
        switch self {
        case .debit:
            return [.capability3DS, .capabilityDebit]
        case .credit:
            return [.capability3DS, .capabilityCredit]
        case nil:
            return .capability3DS
        }
    }
}

extension ApplePayContactDTO {
    func toApplePayContact() -> PKContact {
        let contact = PKContact()
        contact.name = extractPersonNameComponents()
        contact.postalAddress = extractPostalAddress()
        phoneNumber.map { contact.phoneNumber = CNPhoneNumber(stringValue: $0) }
        emailAddress.map { contact.emailAddress = $0 }
        return contact
    }
    
    private func extractPersonNameComponents() -> PersonNameComponents {
        var personName = PersonNameComponents()
        givenName.map { personName.givenName = $0 }
        familyName.map { personName.familyName = $0 }
        phoneticGivenName.map {
            personName.phoneticRepresentation = PersonNameComponents()
            personName.phoneticRepresentation?.givenName = $0
        }
        
        phoneticFamilyName.map {
            personName.phoneticRepresentation = personName.phoneticRepresentation ?? PersonNameComponents()
            personName.phoneticRepresentation?.familyName = $0
        }
        
        return personName
    }
    
    private func extractPostalAddress() -> CNMutablePostalAddress {
        let postalAddress = CNMutablePostalAddress()
        if let addressLines = addressLines?.compactMap({ $0 }) {
            postalAddress.street = addressLines.joined(separator: "\n")
        }

        subLocality.map { postalAddress.subLocality = $0 }
        city.map { postalAddress.city = $0 }
        postalCode.map { postalAddress.postalCode = $0 }
        subAdministrativeArea.map { postalAddress.subAdministrativeArea = $0 }
        administrativeArea.map { postalAddress.state = $0 }
        country.map { postalAddress.country = $0 }
        countryCode.map { postalAddress.isoCountryCode = $0 }
        return postalAddress
    }
}

extension PKContact {
    func toDTO() -> ApplePayContactDTO {
        ApplePayContactDTO(
            phoneNumber: phoneNumber?.stringValue,
            emailAddress: emailAddress as String?,
            givenName: name?.givenName,
            familyName: name?.familyName,
            phoneticGivenName: name?.phoneticRepresentation?.givenName,
            phoneticFamilyName: name?.phoneticRepresentation?.familyName,
            addressLines: postalAddress?.street.components(separatedBy: "\n"),
            subLocality: postalAddress?.subLocality,
            city: postalAddress?.city,
            postalCode: postalAddress?.postalCode,
            subAdministrativeArea: postalAddress?.subAdministrativeArea,
            administrativeArea: postalAddress?.state,
            country: postalAddress?.country,
            countryCode: postalAddress?.isoCountryCode
        )
    }
}

extension PKContactField {
    static func fromString(_ rawValue: String) -> PKContactField {
        switch rawValue {
        case "email", "emailAddress":
            return .emailAddress
        case "phone", "phoneNumber":
            return .phoneNumber
        case "post", "postalAddress":
            return .postalAddress
        case "name":
            return .name
        case "phoneticName":
            return .phoneticName
        default:
            return PKContactField(rawValue: rawValue)
        }
    }
}

extension ApplePayShippingType {
    func toPKShippingType() -> PKShippingType {
        switch self {
        case .shipping:
            return .shipping
        case .delivery:
            return .delivery
        case .storePickup:
            return .storePickup
        case .servicePickup:
            return .servicePickup
        }
    }
}

extension ApplePayShippingMethodDTO {
    func toPKShippingMethod() throws -> PKShippingMethod {
        let pkShippingMethod = PKShippingMethod()
        pkShippingMethod.label = label
        pkShippingMethod.detail = detail
        pkShippingMethod.identifier = identifier
        pkShippingMethod.amount = try amount.toFormattedAmount()
        
        if #available(iOS 15.0, *) {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withFullDate]
            if let startRaw = startDate,
               let endRaw = endDate,
               let startDate = iso8601Formatter.date(from: startRaw),
               let endDate = iso8601Formatter.date(from: endRaw) {
                pkShippingMethod.dateComponentsRange = .init(
                    start: startDate.toComponents(),
                    end: endDate.toComponents()
                )
            }
        }
        return pkShippingMethod
    }
}

extension AmountDTO {
    func toFormattedAmount() throws -> NSDecimalNumber {
        guard let value = Int(exactly: value) else {
            throw AdyenPigeonError(
                code: ApplePayConfigurationErrorCode.invalidAmount,
                message: "Cannot map Int64 to Int.",
                details: nil
            )
        }
        return AmountFormatter.decimalAmount(value, currencyCode: currency)
    }
}

extension ApplePayShippingMethodUpdateDTO {
    func toPKPaymentRequestShippingMethodUpdate() -> PKPaymentRequestShippingMethodUpdate {
        PKPaymentRequestShippingMethodUpdate(
            paymentSummaryItems: summaryItems.compactMap { try? $0?.toApplePaySummeryItem() }
        )
    }
}

@available(iOS 15.0, *)
extension ApplePayCouponCodeUpdateDTO {
    func toPKPaymentRequestCouponCodeUpdate() -> PKPaymentRequestCouponCodeUpdate {
        PKPaymentRequestCouponCodeUpdate(
            errors: errors?.compactMap { $0?.toNSError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0?.toApplePaySummeryItem() },
            shippingMethods: []
        )
    }
}

extension ApplePayShippingContactUpdateDTO {
    func toPKPaymentRequestShippingContactUpdate() -> PKPaymentRequestShippingContactUpdate {
        PKPaymentRequestShippingContactUpdate(
            errors: errors?.compactMap { $0?.toNSError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0?.toApplePaySummeryItem() },
            shippingMethods: shippingMethods?.compactMap { try? $0?.toPKShippingMethod() } ?? []
        )
    }
}

extension PKPaymentSummaryItem {
    func toDTO(currencyCode: String) -> ApplePaySummaryItemDTO {
        ApplePaySummaryItemDTO(
            label: label,
            amount: amount.toDTO(currencyCode: currencyCode),
            type: type.toDTO()
        )
    }
}

extension PKPaymentSummaryItemType {
    func toDTO() -> ApplePaySummaryItemType {
        switch self {
        case .pending:
            return .pending
        case .final:
            return .definite
        @unknown default:
            return .definite
        }
    }
}

extension PKShippingMethod {
    func toDTO(currencyCode: String) -> ApplePayShippingMethodDTO {
        ApplePayShippingMethodDTO(
            label: label,
            detail: detail ?? "",
            amount: amount.toDTO(currencyCode: currencyCode),
            identifier: identifier ?? "",
            startDate: nil,
            endDate: nil
        )
    }
}

extension NSDecimalNumber {
    func toDTO(currencyCode: String) -> AmountDTO {
        AmountDTO(
            currency: currencyCode,
            value: Int64(AmountFormatter.minorUnitAmount(from: decimalValue, currencyCode: currencyCode))
        )
    }
}

extension PKPayment {
    func toAuthorizedPaymentDTO() -> ApplePayAuthorizedPaymentDTO {
        ApplePayAuthorizedPaymentDTO(
            token: token.paymentData.base64EncodedString(),
            network: token.paymentMethod.network?.rawValue ?? "",
            billingContact: billingContact?.toDTO(),
            shippingContact: shippingContact?.toDTO(),
            shippingMethod: nil
        )
    }
}

extension ApplePayAuthorizationResultDTO {
    func toPKPaymentAuthorizationResult() -> PKPaymentAuthorizationResult {
        PKPaymentAuthorizationResult(
            status: isSuccess ? .success : .failure,
            errors: errors?.compactMap { $0?.toNSError() }
        )
    }
}

extension ApplePayPaymentErrorDTO {
    func toNSError() -> Error {
        switch type {
        case .billingAddress:
            return PKPaymentRequest.paymentBillingAddressInvalidError(
                withKey: field ?? "",
                localizedDescription: localizedDescription
            )
        case .shippingAddress:
            return PKPaymentRequest.paymentShippingAddressInvalidError(
                withKey: field ?? "",
                localizedDescription: localizedDescription
            )
        case .contact:
            return PKPaymentRequest.paymentContactInvalidError(
                withContactField: field.map { PKContactField.fromString($0) } ?? .name,
                localizedDescription: localizedDescription
            )
        case .couponCode:
            if #available(iOS 15.0, *) {
                return PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: localizedDescription)
            }
            return NSError(domain: "ApplePayPaymentError", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
        case .shippingAddressUnserviceable:
            return PKPaymentRequest.paymentShippingAddressUnserviceableError(withLocalizedDescription: localizedDescription)
        case .couponCodeExpired:
            if #available(iOS 15.0, *) {
                return PKPaymentRequest.paymentCouponCodeExpiredError(localizedDescription: localizedDescription)
            }
            return NSError(domain: "ApplePayPaymentError", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
        case .unknown:
            return NSError(domain: "ApplePayPaymentError", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
        }
    }
}

@available(iOS 16.0, *)
extension ApplePayRecurringPaymentRequestDTO {
    func toPKRecurringPaymentRequest() throws -> PKRecurringPaymentRequest {
        let recurringPaymentRequest = try PKRecurringPaymentRequest(
            paymentDescription: paymentDescription,
            regularBilling: regularBilling.toPKRecurringPaymentSummaryItem(),
            managementURL: managementUrl.toURL()
        )
        recurringPaymentRequest.trialBilling = try trialBilling?.toPKRecurringPaymentSummaryItem()
        recurringPaymentRequest.billingAgreement = billingAgreement
        recurringPaymentRequest.tokenNotificationURL = try tokenNotificationUrl?.toURL()
        return recurringPaymentRequest
    }
}

@available(iOS 16.0, *)
extension ApplePayRecurringPaymentSummaryItemDTO {
    func toPKRecurringPaymentSummaryItem() throws -> PKRecurringPaymentSummaryItem {
        let summaryItem = try PKRecurringPaymentSummaryItem(
            label: label,
            amount: amount.toFormattedAmount(),
            type: type.toPKPaymentSummaryItemType()
        )
        summaryItem.startDate = try startDate?.toDate()
        summaryItem.intervalUnit = intervalUnit.toCalendarUnit()
        intervalCount.map { summaryItem.intervalCount = Int($0) }
        summaryItem.endDate = try endDate?.toDate()
        return summaryItem
    }
}

extension ApplePayRecurringPaymentIntervalUnit? {
    func toCalendarUnit() -> NSCalendar.Unit {
        switch self {
        case .day:
            return .day
        case .year:
            return .year
        case .month, nil:
            return .month
        }
    }
}

@available(iOS 16.4, *)
extension ApplePayDeferredPaymentRequestDTO {
    func toPKDeferredPaymentRequest() throws -> PKDeferredPaymentRequest {
        let deferredPaymentRequest = try PKDeferredPaymentRequest(
            paymentDescription: paymentDescription,
            deferredBilling: deferredBilling.toPKDeferredPaymentSummaryItem(),
            managementURL: managementUrl.toURL()
        )
        deferredPaymentRequest.billingAgreement = billingAgreement
        deferredPaymentRequest.tokenNotificationURL = try tokenNotificationUrl?.toURL()
        deferredPaymentRequest.freeCancellationDate = try freeCancellationDate?.toDate()
        deferredPaymentRequest.freeCancellationDateTimeZone = freeCancellationTimeZone.map { TimeZone(identifier: $0) } ?? nil
        return deferredPaymentRequest
    }
}

@available(iOS 16.4, *)
extension ApplePayDeferredPaymentSummaryItemDTO {
    func toPKDeferredPaymentSummaryItem() throws -> PKDeferredPaymentSummaryItem {
        let summaryItem = try PKDeferredPaymentSummaryItem(
            label: label,
            amount: amount.toFormattedAmount(),
            type: type.toPKPaymentSummaryItemType()
        )
        summaryItem.deferredDate = try deferredDate.toDate()
        return summaryItem
    }
}

@available(iOS 16.0, *)
extension ApplePayReloadPaymentRequestDTO {
    func toPKAutomaticReloadPaymentRequest() throws -> PKAutomaticReloadPaymentRequest {
        let automaticReloadPaymentRequest = try PKAutomaticReloadPaymentRequest(
            paymentDescription: paymentDescription,
            automaticReloadBilling: automaticReloadBilling.toPKAutomaticReloadPaymentSummaryItem(),
            managementURL: managementUrl.toURL()
        )
        automaticReloadPaymentRequest.billingAgreement = billingAgreement
        automaticReloadPaymentRequest.tokenNotificationURL = try tokenNotificationUrl?.toURL()
        return automaticReloadPaymentRequest
    }
}

@available(iOS 16.0, *)
extension ApplePayReloadPaymentSummaryItemDTO {
    func toPKAutomaticReloadPaymentSummaryItem() throws -> PKAutomaticReloadPaymentSummaryItem {
        let summaryItem = try PKAutomaticReloadPaymentSummaryItem(
            label: label,
            amount: amount.toFormattedAmount(),
            type: type.toPKPaymentSummaryItemType()
        )
        summaryItem.thresholdAmount = try thresholdAmount.toFormattedAmount()
        return summaryItem
    }
}

@available(iOS 16.0, *)
extension ApplePayMultiTokenContextDTO {
    func toPKPaymentTokenContext() throws -> PKPaymentTokenContext {
        try PKPaymentTokenContext(
            merchantIdentifier: merchantId,
            externalIdentifier: externalId,
            merchantName: merchantName,
            merchantDomain: merchantDomain,
            amount: amount.toFormattedAmount()
        )
    }
}

extension String {
    func toDate() throws -> Date {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: self) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        throw AdyenPigeonError(
            code: ApplePayConfigurationErrorCode.invalidDate,
            message: "Cannot map String to Date.",
            details: self
        )
    }

    func toURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw AdyenPigeonError(
                code: ApplePayConfigurationErrorCode.invalidUrl,
                message: "Cannot map String to URL.",
                details: self
            )
        }
        return url
    }
}

private enum ApplePayConfigurationErrorCode {
    static let missingAmount = "apple-pay-missing-amount"
    static let invalidConfiguration = "apple-pay-invalid-configuration"
    static let invalidAmount = "apple-pay-invalid-amount"
    static let invalidUrl = "apple-pay-invalid-url"
    static let invalidDate = "apple-pay-invalid-date"
}

extension Date {
    func toComponents() -> DateComponents {
        Calendar.current.dateComponents([.calendar, .year, .month, .day], from: self)
    }
}

extension ApplePayDetails {
    func getExtraData() -> [String: Any?] {
        var dictionary: [String: Any] = [:]
        dictionary[ApplePayKeys.General.network] = network
        billingContact.map { dictionary[ApplePayKeys.General.billingContact] = $0.toJsonObject() }
        shippingContact.map { dictionary[ApplePayKeys.General.shippingContact] = $0.toJsonObject() }
        shippingMethod.map { dictionary[ApplePayKeys.General.shippingMethod] = $0.toJsonObject() }
        return dictionary
    }
}

extension PKContact {
    func toJsonObject() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        name.map {
            dictionary[ApplePayKeys.Contact.givenName] = $0.givenName
            dictionary[ApplePayKeys.Contact.familyName] = $0.familyName
        }
        name?.phoneticRepresentation.map {
            dictionary[ApplePayKeys.Contact.phoneticGivenName] = $0.phoneticRepresentation?.givenName
            dictionary[ApplePayKeys.Contact.phoneticFamilyName] = $0.phoneticRepresentation?.familyName
        }
        postalAddress.map {
            dictionary[ApplePayKeys.Contact.addressLines] = $0.street
            dictionary[ApplePayKeys.Contact.subLocality] = $0.subLocality
            dictionary[ApplePayKeys.Contact.city] = $0.city
            dictionary[ApplePayKeys.Contact.postalCode] = $0.postalCode
            dictionary[ApplePayKeys.Contact.subAdministrativeArea] = $0.subAdministrativeArea
            dictionary[ApplePayKeys.Contact.administrativeArea] = $0.state
            dictionary[ApplePayKeys.Contact.country] = $0.country
            dictionary[ApplePayKeys.Contact.countryCode] = $0.isoCountryCode
        }
        emailAddress.map { dictionary[ApplePayKeys.Contact.emailAddress] = $0 }
        phoneNumber.map { dictionary[ApplePayKeys.Contact.phoneNumber] = $0.stringValue }
        return dictionary
    }
}

extension PKShippingMethod {
    func toJsonObject() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        identifier.map { dictionary[ApplePayKeys.ShippingMethod.identifier] = $0 }
        detail.map { dictionary[ApplePayKeys.ShippingMethod.detail] = $0 }
        if #available(iOS 15.0, *) {
            dateComponentsRange.map { dictionary[ApplePayKeys.ShippingMethod.dateComponentsRange] = $0.toJsonObject() }
        }
        return dictionary
    }
}

@available(iOS 15.0, *)
extension PKDateComponentsRange {
    func toJsonObject() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        startDateComponents.date.map { dictionary[ApplePayKeys.ShippingMethod.startDate] = $0.ISO8601Format() }
        endDateComponents.date.map { dictionary[ApplePayKeys.ShippingMethod.endDate] = $0.ISO8601Format() }
        return dictionary
    }
}

internal enum ApplePayKeys {
    enum General {
        static let network = "network"
        static let billingContact = "billingContact"
        static let shippingContact = "shippingContact"
        static let shippingMethod = "shippingMethod"
    }
    
    enum Contact {
        static var phoneNumber = "phoneNumber"
        static var emailAddress = "emailAddress"
        static var givenName = "givenName"
        static var familyName = "familyName"
        static var phoneticGivenName = "phoneticGivenName"
        static var phoneticFamilyName = "phoneticFamilyName"
        static var addressLines = "addressLines"
        static var subLocality = "subLocality"
        static var city = "city"
        static var postalCode = "postalCode"
        static var subAdministrativeArea = "subAdministrativeArea"
        static var administrativeArea = "administrativeArea"
        static var country = "country"
        static var countryCode = "countryCode"
    }

    enum ShippingMethod {
        static var identifier = "identifier"
        static var detail = "detail"
        static var dateComponentsRange = "dateComponentsRange"
        static var startDate = "startDate"
        static var endDate = "endDate"
    }
}
