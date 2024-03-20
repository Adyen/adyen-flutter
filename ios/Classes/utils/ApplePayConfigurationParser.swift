import Adyen
import PassKit

extension ApplePayConfigurationDTO {
    func toApplePayConfiguration(amount: AmountDTO, countryCode: String) throws -> ApplePayComponent.Configuration {
        let paymentRequest = try buildPaymentRequest(amount: amount, countryCode: countryCode)
        return try ApplePayComponent.Configuration(paymentRequest: paymentRequest, allowOnboarding: allowOnboarding ?? false)
    }
    
    private func buildPaymentRequest(amount: AmountDTO, countryCode: String) throws -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.paymentSummaryItems = try mapToPaymentSummaryItems(summaryItems: summaryItems, amount: amount)
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = amount.currency
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
        
        supportedNetworks.map {
            let supportedNetworksNonNil: [String] = $0.compactMap { $0 }
            paymentRequest.supportedNetworks = mapToSupportedNetworks(supportedNetworks: supportedNetworksNonNil)
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
    
    private func mapToSupportedNetworks(supportedNetworks: [String]) -> [PKPaymentNetwork] {
        let networks = PKPaymentRequest.availableNetworks()
        return networks.filter { supportedNetworks.contains($0.txVariantName) }
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
