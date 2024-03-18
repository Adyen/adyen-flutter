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
        
        if let requiredShippingContactFields {
            paymentRequest.requiredShippingContactFields = mapToContactFields(contactFields: requiredShippingContactFields)
        }
        
        if let requiredBillingContactFields = requiredShippingContactFields {
            paymentRequest.requiredBillingContactFields = mapToContactFields(contactFields: requiredBillingContactFields)
        }
        
        if let shippingType = applePayShippingType {
            paymentRequest.shippingType = shippingType.toPKShippingType()
        }
        
        if let supportedCountries {
            paymentRequest.supportedCountries = .init(supportedCountries.compactMap { $0 })
        }
        
        if let shippingMethods {
            paymentRequest.shippingMethods = try shippingMethods.compactMap { try $0?.toPKShippingMethod() }
        }
        
        if #available(iOS 15.0, *) {
            if let allowShippingContactEditing {
                //We have to use enabled until we forcing the newest Xcode version. Otherwise the build fails.
                paymentRequest.shippingContactEditingMode = allowShippingContactEditing == true ? PKShippingContactEditingMode.enabled : PKShippingContactEditingMode.storePickup
            }
        }
        
        if let supportedNetworks {
            let supportedNetworksNonNil: [String] = supportedNetworks.compactMap { $0 }
            paymentRequest.supportedNetworks = mapToSupportedNetworks(supportedNetworks: supportedNetworksNonNil)
        }
        
        if let applicationData {
            paymentRequest.applicationData = Data(applicationData.utf8)
        }

        return paymentRequest
    }
    
    private func addShippingMethodToSummaryItems(paymentRequest: PKPaymentRequest) {
        guard let shippingMethod = paymentRequest.shippingMethods?.first else {
            return
        }
        
        if let last = paymentRequest.paymentSummaryItems.last {
            paymentRequest.paymentSummaryItems = paymentRequest.paymentSummaryItems.dropLast()
            paymentRequest.paymentSummaryItems.append(shippingMethod)
            paymentRequest.paymentSummaryItems.append(.init(label: last.label,
                                                            amount: NSDecimalNumber(value: last.amount.floatValue + shippingMethod.amount.floatValue)))
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
            PKPaymentSummaryItemType.pending
        case .definite:
            PKPaymentSummaryItemType.final
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
        if let phoneNumber {
            contact.phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        }
        
        if let emailAddress {
            contact.emailAddress = emailAddress
        }
        
        return contact
    }
    
    private func extractPersonNameComponents() -> PersonNameComponents {
        var personName = PersonNameComponents()
        if let givenName {
            personName.givenName = givenName
        }
   
        if let familyName {
            personName.familyName = familyName
        }
        
        if let phoneticGivenName {
            personName.phoneticRepresentation = PersonNameComponents()
            personName.phoneticRepresentation?.givenName = phoneticGivenName
        }
        
        if let phoneticFamilyName {
            personName.phoneticRepresentation = personName.phoneticRepresentation ?? PersonNameComponents()
            personName.phoneticRepresentation?.familyName = phoneticFamilyName
        }
        
        return personName
    }
    
    private func extractPostalAddress() -> CNMutablePostalAddress {
        let postalAddress = CNMutablePostalAddress()
        if let addressLines = addressLines?.compactMap({ $0 }) {
            postalAddress.street = addressLines.joined(separator: "\n")
        }

        if let subLocality {
            postalAddress.subLocality = subLocality
        }

        if let city {
            postalAddress.city = city
        }

        if let postalCode {
            postalAddress.postalCode = postalCode
        }

        if let subAdministrativeArea {
            postalAddress.subAdministrativeArea = subAdministrativeArea
        }

        if let administrativeArea {
            postalAddress.state = administrativeArea
        }

        if let country {
            postalAddress.country = country
        }

        if let countryCode {
            postalAddress.isoCountryCode = countryCode
        }

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
