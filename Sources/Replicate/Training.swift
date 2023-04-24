import struct Foundation.Date
import struct Foundation.URL
import struct Foundation.TimeInterval
import struct Dispatch.DispatchTime

/// A training with unspecified inputs and outputs.
public typealias AnyTraining = Training<[String: Value]>

/// A training made by a model hosted on Replicate.
public struct Training<Input>: Identifiable where Input: Codable {
    public typealias ID = String

    public struct Output: Hashable, Codable {
        public var version: Model.Version.ID
        public var weights: URL?
    }

    /// Source for creating a training.
    public enum Source: String, Codable {
        /// The training was made on the web.
        case web

        /// The training was made using the API.
        case api
    }

    /// Metrics for the training.
    public struct Metrics: Hashable {
        /// How long it took to create the training, in seconds.
        public let predictTime: TimeInterval?
    }

    /// The unique ID of the prediction.
    /// Can be used to get a single prediction.
    ///
    /// - SeeAlso: ``Client/getPrediction(id:)``
    public let id: ID

    /// The version of the model used to create the prediction.
    public let versionID: Model.Version.ID

    /// Where the prediction was made.
    public let source: Source?

    /// The model's input as a JSON object.
    ///
    /// The input depends on what model you are running.
    /// To see the available inputs,
    /// click the "Run with API" tab on the model you are running.
    /// For example,
    /// [stability-ai/stable-diffusion](https://replicate.com/stability-ai/stable-diffusion)
    /// takes `prompt` as an input.
    ///
    /// Files should be passed as data URLs or HTTP URLs.
    public let input: Input

    /// The output of the model for the prediction, if completed successfully.
    public let output: Output?

    /// The status of the prediction.
    public let status: Status

    /// The error encountered during the prediction, if any.
    public let error: Error?

    /// Logging output for the prediction.
    public let logs: String?

    /// Metrics for the training.
    public let metrics: Metrics?

    /// When the training was created.
    public let createdAt: Date

    /// When the training was completed.
    public let completedAt: Date?

    // MARK: -

    /// Cancel the training.
    ///
    /// - Parameters:
    ///     - client: The client used to make API requests.
    public mutating func cancel(with client: Client) async throws {
        self = try await client.cancelTraining(Self.self, id: id)
    }
}

// MARK: - Decodable

extension Training: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case versionID = "version"
        case source
        case input
        case output
        case status
        case error
        case logs
        case metrics
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

extension Training.Metrics: Codable {
    private enum CodingKeys: String, CodingKey {
        case predictTime = "predict_time"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.predictTime = try container.decodeIfPresent(TimeInterval.self, forKey: .predictTime)
    }
}

// MARK: - Hashable

extension Training: Equatable where Input: Equatable {}
extension Training: Hashable where Input: Hashable {}
