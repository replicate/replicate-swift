import Foundation

/// An error returned by the Replicate HTTP API
public struct Error: Swift.Error, Hashable, Decodable {
    /// A description of the error.
    public let detail: String
}

// MARK: - LocalizedError

extension Error: LocalizedError {
    public var errorDescription: String? {
        return self.detail
    }
}

// MARK: - CustomStringConvertible

extension Error: CustomStringConvertible {
    public var description: String {
        return self.detail
    }
}
