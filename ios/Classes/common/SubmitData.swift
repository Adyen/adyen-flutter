import Foundation

internal struct SubmitData {
    let data: [String: Any]
    let extra: [String: Any?]?

    func toJsonObject() -> [String: Any?] {
        [
            Key.data: data,
            Key.extra: extra
        ]
    }

    private enum Key {
        static let data = "data"
        static let extra = "extra"
    }
}
