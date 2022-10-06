import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Dispatch.DispatchTime

import AnyCodable

/// A prediction with unspecified inputs and outputs.
public typealias AnyPrediction = Prediction<AnyCodable, AnyCodable>

/// A prediction made by a model hosted on Replicate.
public struct Prediction<Input, Output>: Identifiable where Input: Codable, Output: Codable {
    public typealias ID = String

    /// Source for creating a prediction.
    public enum Source: String, Codable {
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
    public enum Status: String, Hashable, Codable {
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
    public let input: Input

    /// The output of the model for the prediction, if completed successfully.
    public let output: Output?

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

    // MARK: -

    public mutating func wait(
        with client: Client,
        delay: TimeInterval = 1.0,
        priority: TaskPriority? = nil,
        timeout: TimeInterval? = nil,
        maximumRetries: Int? = nil
    ) async throws {
        self = try await Self.wait(for: self,
                                   with: client,
                                   priority: priority,
                                   deadline: timeout.flatMap {
                                    DispatchTime.now().advanced(by: .nanoseconds(Int($0 * 1e+9)))
                                   },
                                   maximumRetries: maximumRetries)
    }

    private static func wait(
        for current: Self,
        with client: Client,
        delay: TimeInterval = 1.0,
        priority: TaskPriority?,
        deadline: DispatchTime?,
        maximumRetries: Int?
    ) async throws -> Self {
        guard !current.status.terminated else { return current }
        guard maximumRetries.flatMap({ $0 > 0 }) ?? true else { throw CancellationError() }
        guard deadline.flatMap({ $0 > .now() }) ?? true else { throw CancellationError() }

        let id = current.id
        let updated = try await withThrowingTaskGroup(of: Self.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(delay * 1e+9))
                return try await client.getPrediction(Self.self, id: id)
            }

            if let deadline {
                group.addTask {
                    try await Task.sleep(nanoseconds: deadline.uptimeNanoseconds - DispatchTime.now().uptimeNanoseconds)
                    throw CancellationError()
                }
            }

            let value = try await group.next()
            group.cancelAll()

            return value ?? current
        }

        if updated.status.terminated {
            return updated
        } else {
            return try await wait(for: updated,
                                  with: client,
                                  priority: priority,
                                  deadline: deadline,
                                  maximumRetries: maximumRetries.flatMap({ $0 - 1 }))
        }
    }

    public mutating func cancel(with client: Client) async throws {
        self = try await client.cancelPrediction(Self.self, id: id)
    }
}

// MARK: - Decodable

extension Prediction: Codable {
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

extension Prediction.Metrics: Codable {
    private enum CodingKeys: String, CodingKey {
        case predictTime = "predict_time"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.predictTime = try container.decodeIfPresent(TimeInterval.self, forKey: .predictTime)
    }
}

// MARK: - Hashable

extension Prediction: Equatable where Input: Equatable, Output: Equatable {}
extension Prediction: Hashable where Input: Hashable, Output: Hashable {}
