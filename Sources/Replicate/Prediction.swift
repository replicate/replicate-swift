import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.URL
import class Foundation.Progress
import struct Dispatch.DispatchTime

import RegexBuilder

/// A prediction with unspecified inputs and outputs.
public typealias AnyPrediction = Prediction<[String: Value], Value>

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

    /// The unique ID of the prediction.
    /// Can be used to get a single prediction.
    ///
    /// - SeeAlso: ``Client/getPrediction(id:)``
    public let id: ID

    /// The model used to create the prediction.
    public let modelID: Model.ID

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

    /// When the prediction was started
    public let startedAt: Date?

    /// When the prediction was completed.
    public let completedAt: Date?

    /// A convenience object that can be used to construct new API requests against the given prediction.
    public let urls: [String: URL]

    // MARK: -

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public var progress: Progress? {
        guard let logs = self.logs else { return nil }

        let regex: Regex = #/^\s*(\d+)%\s*\|.+?\|\s*(\d+)\/(\d+)/#

        let lines = logs.split(separator: "\n")
        guard !lines.isEmpty else { return nil }

        for line in lines.reversed() {
            let lineString = String(line).trimmingCharacters(in: .whitespaces)
            if let match = try? regex.firstMatch(in: lineString),
               let current = Int64(match.output.2),
               let total = Int64(match.output.3)
            {
                let progress = Progress(totalUnitCount: total)
                progress.completedUnitCount = current
                return progress
            }
        }

        return nil
    }

    // MARK: -

    /// Wait for the prediction to complete.
    ///
    /// - Parameters:
    ///     - client: The client used to make API requests.
    ///     - delay: The delay between requests.
    ///     - priority: The task priority.
    ///     - timeout: If specified,
    ///                the total amount of time to wait
    ///                before throwing ``CancellationError``.
    ///     - maximumRetries: If specified,
    ///                       the maximum number of requests to make to the API
    ///                       before throwing ``CancellationError``.
    /// - Throws: ``CancellationError`` if the prediction was canceled.
    public mutating func wait(
        with client: Client,
        priority: TaskPriority? = nil
    ) async throws {
        var retrier: Client.RetryPolicy.Retrier = client.retryPolicy.makeIterator()
        self = try await Self.wait(for: self,
                                   with: client,
                                   priority: priority,
                                   retrier: &retrier)
    }

    /// Waits for a prediction to complete and returns the updated prediction.
    ///
    /// - Parameters:
    ///     - current: The prediction to wait for.
    ///     - client: The client used to make API requests.
    ///     - priority: The task priority.
    ///     - retrier: An instance of the client retry policy.
    /// - Returns: The updated prediction.
    /// - Throws: ``CancellationError`` if the prediction was canceled.
    public static func wait(
        for current: Self,
        with client: Client,
        priority: TaskPriority? = nil,
        retrier: inout Client.RetryPolicy.Iterator
    ) async throws -> Self {
        guard !current.status.terminated else { return current }
        guard let delay = retrier.next() else { throw CancellationError() }

        let id = current.id
        let updated = try await withThrowingTaskGroup(of: Self.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(delay * 1e+9))
                return try await client.getPrediction(Self.self, id: id)
            }

            if let deadline = retrier.deadline {
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
                                  retrier: &retrier)
        }
    }

    /// Cancel the prediction.
    ///
    /// - Parameters:
    ///     - client: The client used to make API requests.
    public mutating func cancel(with client: Client) async throws {
        self = try await client.cancelPrediction(Self.self, id: id)
    }
}

// MARK: - Decodable

extension Prediction: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case modelID = "model"
        case versionID = "version"
        case source
        case input
        case output
        case status
        case error
        case logs
        case metrics
        case createdAt = "created_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case urls
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
