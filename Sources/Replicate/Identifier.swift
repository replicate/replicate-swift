/// An identifier in the form of "{owner}/{name}:{version}".
public struct Identifier: Hashable {
    /// The name of the user or organization that owns the model.
    public let owner: String

    /// The name of the model.
    public let name: String

    /// The version.
    let version: Model.Version.ID?
}

// MARK: - Equatable & Comparable

extension Identifier: Equatable, Comparable {
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedSame
    }

    public static func < (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedAscending
    }
}

// MARK: - RawRepresentable

extension Identifier: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        let components = rawValue.split(separator: "/")
        guard components.count == 2 else { return nil }

        if components[1].contains(":") {
            let nameAndVersion = components[1].split(separator: ":")
            guard nameAndVersion.count == 2 else { return nil }

            self.init(owner: String(components[0]),
                      name: String(nameAndVersion[0]),
                      version: Model.Version.ID(nameAndVersion[1]))
        } else {
            self.init(owner: String(components[0]),
                      name: String(components[1]),
                      version: nil)
        }
    }

    public var rawValue: String {
        if let version = version {
            return "\(owner)/\(name):\(version)"
        } else {
            return "\(owner)/\(name)"
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension Identifier: ExpressibleByStringLiteral {
    public init!(stringLiteral value: StringLiteralType) {
       guard let identifier = Identifier(rawValue: value) else {
           fatalError("Invalid Identifier string literal: \(value)")
       }

       self = identifier
   }
}
