//
//  ActionComponentDataModel.swift
//  adyen_checkout
//
//  Created by Robert Schulze Dieckhoff on 30/08/2023.
//

import Foundation
import Adyen

struct ActionComponentDataModel : Encodable {
    
     let details: AnyEncodable
    
     let paymentData: String?
}
