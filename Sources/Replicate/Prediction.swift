import struct Foundation.Date
import struct Foundation.TimeInterval

import AnyCodable

/// A prediction made by a model hosted on Replicate.
public struct Prediction: Hashable, Identifiable {
    public typealias ID = String

    /// Source for creating a prediction.
    public enum Source: String, Decodable {
        /// The prediction was made on the web.
        case web

        /// The prediction was made using the API.
        case api
    }

    /// Metrics for the prediction.
    public struct Metrics: Hashable {
        /// How long it took to create the prediction, in seconds.
        public let predictTime: TimeInterval?
    }

    /// The status of the prediction.
    public enum Status: String, Hashable, Decodable {
        /// The prediction is starting up.
        /// If this status lasts longer than a few seconds,
        /// then it's typically because a new worker is being started to run the prediction.
        case starting

        /// The `predict()` method of the model is currently running.
        case processing

        /// The prediction completed successfully.
        case succeeded

        /// The prediction encountered an error during processing.
        case failed

        /// The prediction was canceled by the user.
        case canceled

        public var terminated: Bool {
            switch self {
            case .starting, .processing:
                return false
            default:
                return true
            }
        }
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
    public let input: AnyDecodable

    /// The output of the model for the prediction, if completed successfully.
    public let output: AnyDecodable?

    /// The status of the prediction.
    public let status: Status

    /// The error encountered during the prediction, if any.
    public let error: Error?

    /// Logging output for the prediction.
    public let logs: String?

    /// Metrics for the prediction.
    public let metrics: Metrics?

    /// When the prediction was created.
    public let createdAt: Date

    /// When the prediction was completed.
    public let completedAt: Date?
}

// MARK: - Decodable

extension Prediction: Decodable {
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

extension Prediction.Metrics: Decodable {
    private enum CodingKeys: String, CodingKey {
        case predictTime = "predict_time"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.predictTime = try container.decodeIfPresent(TimeInterval.self, forKey: .predictTime)
    }
}
