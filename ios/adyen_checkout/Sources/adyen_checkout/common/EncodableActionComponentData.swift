import Adyen
import Foundation

internal struct EncodableActionComponentData: Encodable {
    let data: ActionComponentData

    var jsonString: String {
        get throws {
            let encoded = try JSONEncoder().encode(self)
            guard let value = String(data: encoded, encoding: .utf8) else {
                throw PlatformError(errorDescription: "Unable to encode additional details.")
            }
            return value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.details.encodable, forKey: .details)
        try container.encodeIfPresent(data.paymentData, forKey: .paymentData)
    }

    private enum CodingKeys: String, CodingKey {
        case details
        case paymentData
    }
}
