import Foundation
import Adyen

struct ActionComponentDataModel : Encodable {
    
     let details: AnyEncodable
    
     let paymentData: String?
}
