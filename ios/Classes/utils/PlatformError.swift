import Foundation

public struct PlatformError: Error, LocalizedError {
    
    public var errorDescription: String?
    
    public init(errorDescription: String? = nil) {
        self.errorDescription = errorDescription
    }
}
