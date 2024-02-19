import struct Foundation.Date

/// A deployment of a model on Replicate.
public struct Deployment: Hashable {
    /// The owner of the deployment.
    public let owner: String

    /// The name of the deployment.
    public let name: String

    /// A release of a deployment.
    public struct Release: Hashable {
        /// The release number.
        let number: Int

        /// The model.
        let model: Model.ID

        /// The model version.
        let version: Model.Version.ID

        /// The time at which the release was created.
        let createdAt: Date

        /// The account that created the release
        let createdBy: Account

        /// The configuration of a deployment.
        public struct Configuration: Hashable {
            /// The configured hardware SKU.
            public let hardware: Hardware.ID

            /// A scaling configuration for a deployment.
            public struct Scaling: Hashable {
                /// The maximum number of instances.
                public let maxInstances: Int

                /// The minimum number of instances.
                public let minInstances: Int
            }

            /// The scaling configuration for the deployment.
            public let scaling: Scaling
        }

        /// The deployment configuration.
        public let configuration: Configuration
    }

    public let currentRelease: Release?
}

// MARK: - Identifiable

extension Deployment: Identifiable {
    public typealias ID = String

    /// The ID of the model.
    public var id: ID { "\(owner)/\(name)" }
}

// MARK: - Codable

extension Deployment: Codable {
    public enum CodingKeys: String, CodingKey {
        case owner
        case name
        case currentRelease = "current_release"
    }
}

extension Deployment.Release: Codable {
    public enum CodingKeys: String, CodingKey {
        case number
        case model
        case version
        case createdAt = "created_at"
        case createdBy = "created_by"
        case configuration
    }
}

extension Deployment.Release.Configuration: Codable {
    public enum CodingKeys: String, CodingKey {
        case hardware
        case scaling
    }
}

extension Deployment.Release.Configuration.Scaling: Codable {
    public enum CodingKeys: String, CodingKey {
        case minInstances = "min_instances"
        case maxInstances = "max_instances"
    }
}
