import Adyen
import Foundation

struct ActionComponentDataModel: Encodable {
    let details: AnyEncodable

    let paymentData: String?
}
