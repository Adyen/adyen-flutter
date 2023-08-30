//
//  ResultCode.swift
//  adyen_checkout
//
//  Created by Robert Schulze Dieckhoff on 30/08/2023.
//

import Foundation

enum ResultCode: String, Decodable {
    case authorised = "Authorised"
    case refused = "Refused"
    case pending = "Pending"
    case cancelled = "Cancelled"
    case error = "Error"
    case received = "Received"
    case redirectShopper = "RedirectShopper"
    case identifyShopper = "IdentifyShopper"
    case challengeShopper = "ChallengeShopper"
    case presentToShopper = "PresentToShopper"
}
