/// A deployment of a model on Replicate.
public enum Deployment {
    /// A deployment identifier.
    public struct ID: Hashable {
        /// The owner of the deployment.
        public let owner: String

        /// The name of the deployment.
        public let name: String
    }
}

// MARK: - CustomStringConvertible

extension Deployment.ID: CustomStringConvertible {
    public var description: String {
        return "\(owner)/\(name)"
    }
}

// MARK: - ExpressibleByStringLiteral

extension Deployment.ID: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        let components = value.split(separator: "/")
        guard components.count == 2 else { fatalError("Invalid deployment ID: \(value)") }
        self.init(owner: String(components[0]), name: String(components[1]))
    }
}

// MARK: - Codable

extension Deployment.ID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(stringLiteral: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
