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
    
    func toJsonString() throws -> String {
        try toJsonObject().toJsonStringRepresentation()
    }

    private enum Key {
        static let data = "data"
        static let extra = "extra"
    }
}
