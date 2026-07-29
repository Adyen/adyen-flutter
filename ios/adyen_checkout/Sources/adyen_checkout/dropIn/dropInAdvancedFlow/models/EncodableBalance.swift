// TODO: v6 migration - DropIn has no public API on iOS in 6.0.0-alpha.1 (Balance is now
// package-access). The only caller (partial payment balance check) is already commented out
// in DropInPlatformApi.swift. Restore once DropIn ships publicly on iOS.
// import Adyen
// import Foundation
//
// extension Balance: Decodable {
//
//     public init(from decoder: any Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         let availableAmount = try container.decode(Amount.self, forKey: .availableAmount)
//         let transactionLimit = try container.decodeIfPresent(Amount.self, forKey: .transactionLimit)
//         self = .init(availableAmount: availableAmount, transactionLimit: transactionLimit)
//     }
//
//     private enum CodingKeys: String, CodingKey {
//         case availableAmount = "balance"
//         case transactionLimit
//     }
// }
