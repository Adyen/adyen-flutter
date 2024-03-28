import Foundation

internal struct SubmitData {
    let paymentData: [String: Any]
    let extraData: [String: Any?]?

    func toJsonObject() -> [String: Any?] {
        [
            Key.paymentData: paymentData,
            Key.extraData: extraData
        ]
    }

    private enum Key {
        static let paymentData = "paymentData"
        static let extraData = "extraData"
    }
}
