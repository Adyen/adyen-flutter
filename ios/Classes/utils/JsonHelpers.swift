import Adyen
import Foundation

internal extension Encodable {
    var jsonObject: [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }

        return object
    }
}

internal extension Decodable {
    init(from jsonObject: NSDictionary) throws {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension Dictionary {
    func toJsonStringRepresentation() throws -> String {
        let JSONData = try JSONSerialization.data(
            withJSONObject: self,
            options: []
        )
        guard let encodedString = String(data: JSONData, encoding: .utf8) else {
            throw PlatformError(errorDescription: "Unable to encode Json data")
        }

        return encodedString
    }
}
