import Adyen
import PassKit

extension ApplePayConfigurationDTO {
    func toApplePayConfiguration(amount: AmountDTO, countryCode: String) throws -> ApplePayComponent.Configuration {
        let summaryItems =  try mapToPaymentSummaryItems(summaryItems: summaryItems, amount: amount)
        let paymentRequest = try buildPaymentRequest(countryCode: countryCode, currencyCode: amount.currency, summaryItems: summaryItems)
        return try ApplePayComponent.Configuration(paymentRequest: paymentRequest, allowOnboarding: allowOnboarding ?? false)
    }
    
    private func buildPaymentRequest(countryCode: String, currencyCode: String, summaryItems: [PKPaymentSummaryItem]) throws -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.paymentSummaryItems = summaryItems
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.billingContact = billingContact?.toApplePayContact()
        paymentRequest.shippingContact = shippingContact?.toApplePayContact()
        paymentRequest.merchantCapabilities = merchantCapability.toMerchantCapability()
        requiredShippingContactFields.map { paymentRequest.requiredShippingContactFields = mapToContactFields(contactFields: $0) }
        requiredShippingContactFields.map { paymentRequest.requiredBillingContactFields = mapToContactFields(contactFields: $0) }
        applePayShippingType.map { paymentRequest.shippingType = $0.toPKShippingType() }
        supportedCountries.map { paymentRequest.supportedCountries = .init($0.compactMap { $0 }) }
        try shippingMethods.map { paymentRequest.shippingMethods = try $0.compactMap { try $0?.toPKShippingMethod() }}
        
        if #available(iOS 15.0, *) {
            allowShippingContactEditing.map {
                // We have to use enabled until we forcing the newest Xcode version. Otherwise the build fails.
                paymentRequest.shippingContactEditingMode = $0 ? PKShippingContactEditingMode.enabled : PKShippingContactEditingMode.storePickup
            }
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
    
    private func mapToPaymentSummaryItems(summaryItems: [ApplePaySummaryItemDTO?]?, amount: AmountDTO) throws -> [PKPaymentSummaryItem] {
        guard let summaryItems else {
            let formattedAmount = try amount.toFormattedAmount()
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
            throw PlatformError(errorDescription: "Cannot map Int64 to Int.")
        }
        return AmountFormatter.decimalAmount(value, currencyCode: currency)
    }
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
