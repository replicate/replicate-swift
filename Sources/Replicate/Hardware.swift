// Hardware for running a model on Replicate.
public struct Hardware: Hashable, Codable {
    public typealias ID = String

    /// The product identifier for the hardware.
    ///
    /// For example, "gpu-a40-large".
    public let sku: String

    /// The name of the hardware.
    ///
    /// For example, "Nvidia A40 (Large) GPU".
    public let name: String
}

// MARK: - Identifiable

extension Hardware: Identifiable {
    public var id: String {
        return self.sku
    }
}

// MARK: - CustomStringConvertible

extension Hardware: CustomStringConvertible {
    public var description: String {
        return self.name
    }
}
