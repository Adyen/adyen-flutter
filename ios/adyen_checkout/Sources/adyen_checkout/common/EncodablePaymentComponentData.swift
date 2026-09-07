import Adyen
import Foundation

internal struct EncodablePaymentComponentData: Encodable {
    let data: PaymentComponentData

    var jsonString: String {
        get throws {
            let encoded = try JSONEncoder().encode(self)
            guard let value = String(data: encoded, encoding: .utf8) else {
                throw PlatformError(errorDescription: "Unable to encode payment data.")
            }
            return value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.paymentMethod.encodable, forKey: .paymentMethod)
        try container.encodeIfPresent(data.order, forKey: .order)
        try container.encodeIfPresent(data.storePaymentMethod, forKey: .storePaymentMethod)
        try container.encodeIfPresent(data.billingAddress, forKey: .billingAddress)
        try container.encodeIfPresent(data.deliveryAddress, forKey: .deliveryAddress)
        try container.encodeIfPresent(data.shopperName, forKey: .shopperName)
        try container.encodeIfPresent(data.telephoneNumber, forKey: .telephoneNumber)
        try container.encodeIfPresent(data.emailAddress, forKey: .shopperEmail)
        try container.encodeIfPresent(data.socialSecurityNumber, forKey: .socialSecurityNumber)
        try container.encodeIfPresent(data.installments, forKey: .installments)
        try container.encode(true, forKey: .supportNativeRedirect)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethod
        case order
        case storePaymentMethod
        case billingAddress
        case deliveryAddress
        case shopperName
        case telephoneNumber
        case shopperEmail
        case socialSecurityNumber
        case installments
        case supportNativeRedirect
    }
}
