import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import AnyCodable

/// A Replicate HTTP API client.
///
/// See https://replicate.com/docs/reference/http
public class Client {
    /// A namespace for pagination cursor and page types.
    public enum Pagination {
        /// A paginated collection of results.
        public struct Page <Result> {
            /// A pointer to the previous page of results
            public let previous: Cursor?

            /// A pointer to the next page of results.
            public let next: Cursor?

            /// The results for this page.
            public let results: [Result]
        }

        /// A pointer to a page of results.
        public struct Cursor: RawRepresentable, Hashable {
            public var rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }

    public struct RetryPolicy: Equatable, Sequence {
        public enum Strategy: Hashable {
            case constant(base: TimeInterval = 2.0,
                          jitter: Double = 0.0)

            case exponential(base: TimeInterval = 2.0,
                             multiplier: Double = 2.0,
                             jitter: Double = 0.5)
        }

        public let strategy: Strategy
        public let timeout: TimeInterval?
        public let maximumInterval: TimeInterval?
        public let maximumRetries: Int?

        static let `default` = RetryPolicy(strategy: .exponential(),
                                           timeout: 300.0,
                                           maximumInterval: 30.0,
                                           maximumRetries: 10)

        public init(strategy: Strategy,
                    timeout: TimeInterval? = 300.0,
                    maximumInterval: TimeInterval?,
                    maximumRetries: Int)
        {
            self.strategy = strategy
            self.timeout = timeout
            self.maximumInterval = maximumInterval
            self.maximumRetries = maximumRetries
        }

        public struct Retrier: IteratorProtocol {
            public private(set) var retries: Int = 1
            public let policy: RetryPolicy
            public let deadline: DispatchTime?

            init(policy: RetryPolicy,
                 deadline: DispatchTime?)
            {
                self.policy = policy
                self.deadline = deadline
            }

            public mutating func next() -> TimeInterval? {
                guard policy.maximumRetries.flatMap({ $0 > retries }) ?? true else { return nil }
                guard deadline.flatMap({ $0 > .now() }) ?? true else { return nil }

                defer { retries += 1 }

                let delay: TimeInterval
                switch policy.strategy {
                case .constant(let base, let jitter):
                    delay = base * Double(retries) + Double.random(jitter: jitter)
                case .exponential(let base, let multiplier, let jitter):
                    delay = base * (pow(multiplier, Double(retries))) + Double.random(jitter: jitter)
                }

                return Swift.min(policy.maximumInterval ?? TimeInterval.greatestFiniteMagnitude, delay)
            }
        }

        public func makeIterator() -> Retrier {
            return Retrier(policy: self, deadline: timeout.flatMap {
                .now().advanced(by: .nanoseconds(Int($0 * 1e+9)))
            })
        }
    }

    private let token: String
    internal var session = URLSession(configuration: .default)

    public var retryPolicy: RetryPolicy = .default

    /// Creates a client with the specified API token.
    ///
    /// You can get an Replicate API token on your
    /// [account page](https://replicate.com/account).
    ///
    /// - Parameter token: The API token.
    public init(token: String) {
        self.token = token
    }

    /// Create a prediction
    ///
    /// - Parameters:
    ///    - id:
    ///         The ID of the model version that you want to run.
    ///
    ///         You can get your model's versions using the API,
    ///         or find them on the website by clicking
    ///         the "Versions" tab on the Replicate model page,
    ///         e.g. replicate.com/replicate/hello-world/versions,
    ///         then copying the full SHA256 hash from the URL.
    ///
    ///         The version ID is the same as the Docker image ID
    ///         that's created when you build your model.
    ///    - input:
    ///        The input depends on what model you are running.
    ///
    ///        To see the available inputs,
    ///        click the "Run with API" tab on the model you are running.
    ///        For example, stability-ai/stable-diffusion
    ///        takes `prompt` as an input.
    ///    - webhook:
    ///         A webhook that is called when the prediction has completed.
    ///
    ///         It will be a `POST` request where
    ///         the request body is the same as
    ///         the response body of the get prediction endpoint.
    ///         If there are network problems,
    ///         we will retry the webhook a few times,
    ///         so make sure it can be safely called more than once.
    ///    - wait:
    ///         If set to `true`,
    ///         this method refreshes the prediction until it completes
    ///         (``Prediction/status`` is `.succeeded` or `.failed`).
    ///         By default, this is `false`,
    ///         and this method returns the prediction object encoded
    ///         in the original creation response
    ///         (``Prediction/status`` is `.starting`).
    public func createPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction,
        version id: Model.Version.ID,
        input: Input,
        webhook: URL? = nil,
        wait: Bool = false
    ) async throws -> Prediction<Input, Output> {
        var params: [String: AnyEncodable] = [
            "version": "\(id)",
            "input": AnyEncodable(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.absoluteString)"
        }

        var prediction: Prediction<Input, Output> = try await fetch(.post, "predictions", params: params)
        if wait {
            try await prediction.wait(with: self)
            return prediction
        } else {
            return prediction
        }
    }

    /// Get a prediction
    ///
    /// - Parameter id: The ID of the prediction you want to fetch.
    public func getPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction,
        id: Prediction.ID
    ) async throws -> Prediction<Input, Output> {
        return try await fetch(.get, "predictions/\(id)")
    }

    /// Cancel a prediction
    ///
    /// - Parameter id: The ID of the prediction you want to fetch.
    public func cancelPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction,
        id: Prediction.ID
    ) async throws -> Prediction<Input, Output> {
        return try await fetch(.post, "predictions/\(id)/cancel")
    }

    /// Get a list of predictions
    ///
    /// - Parameter cursor: A pointer to a page of results to fetch.
    public func getPredictions<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction,
        cursor: Pagination.Cursor? = nil
    ) async throws -> Pagination.Page<Prediction<Input, Output>>
    {
        return try await fetch(.get, "predictions", cursor: cursor)
    }

    /// Get a model
    ///
    /// - Parameters:
    ///    - id: The model identifier, comprising
    ///          the name of the user or organization that owns the model and
    ///          the name of the model.
    ///          For example, "stability-ai/stable-diffusion".
    public func getModel(_ id: Model.ID)
        async throws -> Model
    {
        return try await fetch(.get, "models/\(id)")
    }

    /// Get a list of model versions
    ///
    /// - Parameters:
    ///    - id: The model identifier, comprising
    ///          the name of the user or organization that owns the model and
    ///          the name of the model.
    ///          For example, "stability-ai/stable-diffusion".
    ///    - cursor: A pointer to a page of results to fetch.
    public func getModelVersions(_ id: Model.ID,
                                 cursor: Pagination.Cursor? = nil)
        async throws -> Pagination.Page<Model.Version>
    {
        return try await fetch(.get, "models/\(id)/versions", cursor: cursor)
    }

    /// Get a model version
    ///
    /// - Parameters:
    ///    - id: The model identifier, comprising
    ///          the name of the user or organization that owns the model and
    ///          the name of the model.
    ///          For example, "stability-ai/stable-diffusion".
    ///    - version: The ID of the version.
    public func getModelVersion(_ id: Model.ID,
                                version: Model.Version.ID)
        async throws -> Model.Version
    {
        return try await fetch(.get, "models/\(id)/versions/\(version)")
    }

    /// Get a collection of models
    ///
    /// - Parameters:
    ///    - slug:
    ///         The slug of the collection,
    ///         like super-resolution or image-restoration.
    ///
    ///         See <https://replicate.com/collections>
    public func getModelCollection(_ slug: String)
        async throws -> Model.Collection
    {
        return try await fetch(.get, "collections/\(slug)")
    }

    // MARK: -

    private enum Method: String, Hashable {
        case get = "GET"
        case post = "POST"
    }

    private func fetch<T: Decodable>(_ method: Method,
                                     _ path: String,
                                     cursor: Pagination.Cursor?)
    async throws -> Pagination.Page<T> {
        var params: [String: AnyEncodable]? = nil
        if let cursor {
            params = ["cursor": "\(cursor)"]
        }

        return try await fetch(method, path, params: params)
    }

    private func fetch<T: Decodable>(_ method: Method,
                                     _ path: String,
                                     params: [String: AnyEncodable]? = nil)
    async throws -> T {
        var urlComponents = URLComponents(string: "https://api.replicate.com/v1/" + path)
        var httpBody: Data? = nil

        switch method {
        case .get:
            if let params {
                var queryItems: [URLQueryItem] = []
                for (key, value) in params {
                    queryItems.append(URLQueryItem(name: key, value: value.description))
                }
                urlComponents?.queryItems = queryItems
            }
        case .post:
            if let params {
                let encoder = JSONEncoder()
                httpBody = try encoder.encode(params)
            }
        }

        guard let url = urlComponents?.url else {
            throw Error(detail: "invalid request \(method) \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let httpBody {
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        switch (response as? HTTPURLResponse)?.statusCode {
        case (200..<300)?:
            return try decoder.decode(T.self, from: data)
        default:
            if let error = try? decoder.decode(Error.self, from: data) {
                throw error
            }

            if let string = String(data: data, encoding: .utf8) {
                throw Error(detail: "invalid response: \(response) \n \(string)")
            }

            throw Error(detail: "invalid response: \(response)")
        }
    }
}

// MARK: - Decodable

extension Client.Pagination.Page: Decodable where Result: Decodable {
    private enum CodingKeys: String, CodingKey {
        case results
        case previous
        case next
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.previous = try? container.decode(Client.Pagination.Cursor.self, forKey: .previous)
        self.next = try? container.decode(Client.Pagination.Cursor.self, forKey: .next)
        self.results = try container.decode([Result].self, forKey: .results)
    }
}

extension Client.Pagination.Cursor: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let urlComponents = URLComponents(string: string),
           let queryItem = urlComponents.queryItems?.first(where: { $0.name == "cursor" }),
           let value = queryItem.value
        else {
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "invalid cursor")
            throw DecodingError.dataCorrupted(context)
        }

        self.rawValue = value
    }
}

// MARK: -

extension Client.Pagination.Cursor: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}

extension Client.Pagination.Cursor: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: -

private extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom { decoder in
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                   .withFullTime,
                                   .withFractionalSeconds]

        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        return date
    }
}

private extension Double {
    static func random(jitter amount: Double) -> Double {
        return Double.random(in: (-amount / 2)...(amount / 2))
    }
}
