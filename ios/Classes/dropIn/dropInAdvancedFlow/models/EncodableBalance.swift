import Adyen
import Foundation

extension Balance: Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let availableAmount = try container.decode(Amount.self, forKey: .availableAmount)
        let transactionLimit = try container.decodeIfPresent(Amount.self, forKey: .transactionLimit)
        self = .init(availableAmount: availableAmount, transactionLimit: transactionLimit)
    }

    private enum CodingKeys: String, CodingKey {
        case availableAmount = "balance"
        case transactionLimit
    }
}
