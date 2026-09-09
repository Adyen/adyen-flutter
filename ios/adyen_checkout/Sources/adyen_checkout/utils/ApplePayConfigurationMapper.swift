import Adyen
import AdyenComponents
import Contacts
import Foundation
import PassKit

func mapApplePayConfiguration(
    dto: ApplePayConfigurationDTO,
    amount: Adyen.Amount,
    countryCode: String,
    callbacksApi: CheckoutCallbacksFlutterApi?,
    checkoutId: String?
) throws -> ApplePayConfiguration {
    let request = try makeApplePayPaymentRequest(dto: dto, amount: amount, countryCode: countryCode)
    let configuration = try ApplePayConfiguration(paymentRequest: request)
        .allowOnboarding(dto.allowOnboarding ?? true)
    guard let callbacksApi, let checkoutId else { return configuration }
    return dto.attachCallbacks(
        to: configuration,
        callbacksApi: callbacksApi,
        checkoutId: checkoutId,
        currencyCode: amount.currencyCode
    )
}

func makeApplePayPaymentRequest(
    dto: ApplePayConfigurationDTO,
    amount: Adyen.Amount,
    countryCode: String
) throws -> PKPaymentRequest {
    let summaryItems = try dto.summaryItems?.map { try $0.toNativeSummaryItem() } ?? [
        PKPaymentSummaryItem(
            label: dto.merchantName,
            amount: AmountFormatter.decimalAmount(
                amount.value,
                currencyCode: amount.currencyCode,
                localeIdentifier: amount.localeIdentifier
            )
        )
    ]
    let request = PKPaymentRequest()
    request.merchantIdentifier = dto.merchantId
    request.paymentSummaryItems = summaryItems
    request.countryCode = countryCode
    request.currencyCode = amount.currencyCode
    request.billingContact = dto.billingContact?.toNativeContact()
    request.shippingContact = dto.shippingContact?.toNativeContact()
    request.merchantCapabilities = dto.merchantCapability.toNativeCapabilities()
    request.requiredBillingContactFields = dto.requiredBillingContactFields.mapToContactFields()
    request.requiredShippingContactFields = dto.requiredShippingContactFields.mapToContactFields()
    if let shippingType = dto.shippingType {
        request.shippingType = shippingType.toNativeShippingType()
    }
    request.shippingMethods = try dto.shippingMethods?.map { try $0.toNativeShippingMethod() }
    request.applicationData = dto.applicationData.map { Data($0.utf8) }
    request.supportedCountries = dto.supportedCountries.map { Set($0) }
    if #available(iOS 15.0, *) {
        if let allowShippingContactEditing = dto.allowShippingContactEditing {
            request.shippingContactEditingMode = allowShippingContactEditing ? .enabled : .storePickup
        }
        request.supportsCouponCode = dto.supportsCouponCode == true
        request.couponCode = dto.couponCode
    }
    return request
}

private extension [String]? {
    func mapToContactFields() -> Set<PKContactField> {
        Set(self?.compactMap { contactField(from: $0) } ?? [])
    }
}

private func contactField(from value: String) -> PKContactField {
    switch value {
    case "email", "emailAddress": return .emailAddress
    case "phone", "phoneNumber": return .phoneNumber
    case "post", "postalAddress": return .postalAddress
    case "name": return .name
    case "phoneticName": return .phoneticName
    default: return PKContactField(rawValue: value)
    }
}

private extension ApplePayMerchantCapabilityDTO? {
    func toNativeCapabilities() -> PKMerchantCapability {
        switch self {
        case .debit: return [.capability3DS, .capabilityDebit]
        case .credit: return [.capability3DS, .capabilityCredit]
        case nil: return .capability3DS
        }
    }
}

private extension ApplePayShippingTypeDTO {
    func toNativeShippingType() -> PKShippingType {
        switch self {
        case .shipping: return .shipping
        case .delivery: return .delivery
        case .storePickup: return .storePickup
        case .servicePickup: return .servicePickup
        }
    }
}

private extension ApplePaySummaryItemDTO {
    func toNativeSummaryItem() throws -> PKPaymentSummaryItem {
        PKPaymentSummaryItem(
            label: label,
            amount: AmountFormatter.decimalAmount(Int(amount.value), currencyCode: amount.currency),
            type: type == .pending ? .pending : .final
        )
    }
}

private extension ApplePayShippingMethodDTO {
    func toNativeShippingMethod() throws -> PKShippingMethod {
        let method = PKShippingMethod()
        method.label = label
        method.detail = detail
        method.identifier = identifier
        method.amount = try amount.toDecimalAmount()
        return method
    }
}

private extension ApplePayContactDTO {
    func toNativeContact() -> PKContact {
        let contact = PKContact()
        var name = PersonNameComponents()
        name.givenName = givenName
        name.familyName = familyName
        contact.name = name
        let address = CNMutablePostalAddress()
        address.street = addressLines?.joined(separator: "\n") ?? ""
        address.subLocality = subLocality ?? ""
        address.city = city ?? ""
        address.postalCode = postalCode ?? ""
        address.subAdministrativeArea = subAdministrativeArea ?? ""
        address.state = administrativeArea ?? ""
        address.country = country ?? ""
        address.isoCountryCode = countryCode ?? ""
        contact.postalAddress = address
        if let phoneNumber {
            contact.phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        }
        contact.emailAddress = emailAddress
        return contact
    }
}

private extension AmountDTO {
    func toDecimalAmount() throws -> NSDecimalNumber {
        NSDecimalNumber(value: Double(value) / 100.0)
    }
}

extension PKPaymentSummaryItem {
    internal func toDTO(currencyCode: String) -> ApplePaySummaryItemDTO {
        ApplePaySummaryItemDTO(
            label: label,
            amount: AmountDTO(
                currency: currencyCode,
                value: Int64(AmountFormatter.minorUnitAmount(
                    from: amount.decimalValue,
                    currencyCode: currencyCode
                ))
            ),
            type: type == .pending ? .pending : .definite
        )
    }
}

extension PKShippingMethod {
    internal func toDTO(currencyCode: String) -> ApplePayShippingMethodDTO {
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

private extension NSDecimalNumber {
    func toDTO(currencyCode: String) -> AmountDTO {
        AmountDTO(
            currency: currencyCode,
            value: Int64(AmountFormatter.minorUnitAmount(from: decimalValue, currencyCode: currencyCode))
        )
    }
}

extension PKContact {
    internal func toDTO() -> ApplePayContactDTO {
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

extension PKPayment {
    internal func toDTO(currencyCode: String) -> ApplePayAuthorizedPaymentDTO {
        ApplePayAuthorizedPaymentDTO(
            token: token.paymentData.base64EncodedString(),
            network: token.paymentMethod.network?.rawValue ?? "",
            billingContact: billingContact?.toDTO(),
            shippingContact: shippingContact?.toDTO(),
            shippingMethod: shippingMethod?.toDTO(currencyCode: currencyCode)
        )
    }
}

extension ApplePayShippingMethodUpdateDTO {
    internal func toNativeShippingMethodUpdate() -> PKPaymentRequestShippingMethodUpdate {
        PKPaymentRequestShippingMethodUpdate(
            paymentSummaryItems: summaryItems.compactMap { try? $0.toNativeSummaryItem() }
        )
    }
}

extension ApplePayShippingContactUpdateDTO {
    internal func toNativeShippingContactUpdate() -> PKPaymentRequestShippingContactUpdate {
        PKPaymentRequestShippingContactUpdate(
            errors: errors?.compactMap { $0.toNSError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0.toNativeSummaryItem() },
            shippingMethods: shippingMethods?.compactMap { try? $0.toNativeShippingMethod() } ?? []
        )
    }
}

@available(iOS 15.0, *)
extension ApplePayCouponCodeUpdateDTO {
    internal func toNativeCouponCodeUpdate() -> PKPaymentRequestCouponCodeUpdate {
        PKPaymentRequestCouponCodeUpdate(
            errors: errors?.compactMap { $0.toNSError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0.toNativeSummaryItem() },
            shippingMethods: shippingMethods?.compactMap { try? $0.toNativeShippingMethod() } ?? []
        )
    }
}

extension ApplePayAuthorizationResultDTO {
    internal func toNativeAuthorizationResult() -> PKPaymentAuthorizationResult {
        PKPaymentAuthorizationResult(
            status: isSuccess ? .success : .failure,
            errors: errors?.compactMap { $0.toNSError() }
        )
    }
}

private extension ApplePayPaymentErrorDTO {
    func toNSError() -> Error {
        NSError(
            domain: "AdyenCheckout.ApplePay",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
}
