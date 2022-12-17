import struct Foundation.Date
import struct Foundation.URL

import AnyCodable

/// A machine learning model hosted on Replicate.
public struct Model: Hashable {
    /// The visibility of the model.
    public enum Visibility: String, Hashable, Decodable {
        /// Public visibility.
        case `public`

        /// Private visibility.
        case `private`
    }

    /// A version of a model.
    public struct Version: Hashable {
        /// The ID of the version.
        public let id: ID

        /// When the version was created.
        public let createdAt: Date

        /// An OpenAPI description of the model inputs and outputs.
        public let openAPISchema: AnyCodable
    }

    /// A collection of models.
    public struct Collection: Hashable, Decodable {
        /// The name of the collection.
        public let name: String

        /// The slug of the collection,
        /// like super-resolution or image-restoration.
        ///
        /// See <https://replicate.com/collections>
        public let slug: String

        /// A description for the collection.
        public let description: String

        /// A list of models in the collection.
        public let models: [Model]
    }

    /// The name of the user or organization that owns the model.
    public let owner: String

    /// The name of the model.
    public let name: String

    /// A link to the model on Replicate.
    public let url: URL

    /// A link to the model source code on GitHub.
    public let githubURL: URL?

    /// A link to the model's paper.
    public let paperURL: URL?

    /// A link to the model's license.
    public let licenseURL: URL?

    /// A description for the model.
    public let description: String?

    /// The visibility of the model.
    public let visibility: Visibility

    /// The latest version of the model, if any.
    public let latestVersion: Version?
}

// MARK: - Identifiable

extension Model: Identifiable {
    public typealias ID = String

    /// The ID of the model.
    public var id: ID { "\(owner)/\(name)" }
}

extension Model.Version: Identifiable {
    public typealias ID = String
}

extension Model.Collection: Identifiable {
    public typealias ID = String

    /// The ID of the model collection.
    public var id: String { slug }
}

// MARK: - Decodable

extension Model: Decodable {
    private enum CodingKeys: String, CodingKey {
        case owner
        case name
        case url
        case githubURL = "github_url"
        case paperURL = "paper_url"
        case licenseURL = "license_url"
        case description
        case visibility
        case latestVersion = "latest_version"
    }
}

extension Model.Version: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case openAPISchema = "openapi_schema"
    }
}
