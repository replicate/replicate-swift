import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A Replicate HTTP API client.
///
/// See https://replicate.com/docs/reference/http
public class Client {
    /// The base URL for requests made by the client.
    public let baseURLString: String

    /// The value for the `User-Agent` header sent in requests, if any.
    public let userAgent: String?

    /// The API token used in the `Authorization` header sent in requests.
    private let token: String

    /// The underlying client session.
    internal var session = URLSession(configuration: .default)

    /// The retry policy for requests made by the client.
    public var retryPolicy: RetryPolicy = .default

    /// Creates a client with the specified API token.
    ///
    /// You can get an Replicate API token on your
    /// [account page](https://replicate.com/account).
    ///
    /// - Parameter token: The API token.
    public init(
        baseURLString: String = "https://api.replicate.com/v1/",
        userAgent: String? = nil,
        token: String
    )
    {
        var baseURLString = baseURLString
        if !baseURLString.hasSuffix("/") {
            baseURLString = baseURLString.appending("/")
        }

        self.baseURLString = baseURLString
        self.userAgent = userAgent
        self.token = token
    }

    // MARK: -

    /// Runs a model and waits for its output.
    ///
    /// - Parameters:
    ///    - identifier:
    ///        The model version identifier in the format "{owner}/{name}:{version}"
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
    public func run<Input: Codable, Output: Codable>(
        _ identifier: Identifier,
        input: Input,
        webhook: Webhook? = nil,
        _ type: Output.Type = Value.self
    ) async throws -> Output? {
        var prediction: Prediction<Input, Output>
        if let version = identifier.version {
            prediction = try await createPrediction(Prediction<Input, Output>.self,
                                                    version: version,
                                                    input: input,
                                                    webhook: webhook)
        } else {
            prediction = try await createPrediction(Prediction<Input, Output>.self,
                                                    model: "\(identifier.owner)/\(identifier.name)",
                                                    input: input,
                                                    webhook: webhook)
        }

        try await prediction.wait(with: self)

        if prediction.status == .failed {
            throw prediction.error ?? Error(detail: "Prediction failed")
        }

        return prediction.output
    }

    // MARK: -

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
    @available(*, deprecated, message: "wait parameter is deprecated; use ``Prediction/wait(with:)`` or ``Client/run(_:input:webhook:_:)``")
    public func createPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        version id: Model.Version.ID,
        input: Input,
        webhook: Webhook? = nil,
        wait: Bool
    ) async throws -> Prediction<Input, Output> {
        var params: [String: Value] = [
            "version": "\(id)",
            "input": try Value(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.url.absoluteString)"
            params["webhook_events_filter"] = .array(webhook.events.map { "\($0.rawValue)" })
        }

        var prediction: Prediction<Input, Output> = try await fetch(.post, "predictions", params: params)
        if wait {
            try await prediction.wait(with: self)
            return prediction
        } else {
            return prediction
        }
    }

    /// Create a prediction from a model version
    ///
    /// - Parameters:
    ///    - version:
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
    ///    - stream:
    ///         Whether to stream the prediction output.
    ///         By default, this is `false`.
    public func createPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        version id: Model.Version.ID,
        input: Input,
        webhook: Webhook? = nil,
        stream: Bool = false
    ) async throws -> Prediction<Input, Output> {
        var params: [String: Value] = [
            "version": "\(id)",
            "input": try Value(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.url.absoluteString)"
            params["webhook_events_filter"] = .array(webhook.events.map { "\($0.rawValue)" })
        }

        if stream {
            params["stream"] = true
        }

        return try await fetch(.post, "predictions", params: params)
    }

    /// Create a prediction from a model
    ///
    /// - Parameters:
    ///    - model:
    ///         The ID of the model that you want to run.
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
    ///    - stream:
    ///         Whether to stream the prediction output.
    ///         By default, this is `false`.
    public func createPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        model id: Model.ID,
        input: Input,
        webhook: Webhook? = nil,
        stream: Bool = false
    ) async throws -> Prediction<Input, Output> {
        var params: [String: Value] = [
            "input": try Value(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.url.absoluteString)"
            params["webhook_events_filter"] = .array(webhook.events.map { "\($0.rawValue)" })
        }

        if stream {
            params["stream"] = true
        }

        return try await fetch(.post, "models/\(id)/predictions", params: params)
    }

    /// Create a prediction using a deployment
    ///
    /// - Parameters:
    ///    - owner:
    ///         The name of the deployment owner.
    ///    - name:
    ///         The name of the deployment.
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
    ///    - stream:
    ///         Whether to stream the prediction output.
    ///         By default, this is `false`.
    public func createPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        deployment id: Deployment.ID,
        input: Input,
        webhook: Webhook? = nil,
        stream: Bool = false
    ) async throws -> Prediction<Input, Output> {
        var params: [String: Value] = [
            "input": try Value(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.url.absoluteString)"
            params["webhook_events_filter"] = .array(webhook.events.map { "\($0.rawValue)" })
        }

        if stream {
            params["stream"] = true
        }

        return try await fetch(.post, "deployments/\(id)/predictions", params: params)
    }

    @available(*, deprecated, renamed: "listPredictions(_:cursor:)")
    public func getPredictions<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        cursor: Pagination.Cursor? = nil
    ) async throws -> Pagination.Page<Prediction<Input, Output>>
    {
        return try await listPredictions(type, cursor: cursor)
    }

    /// List predictions
    ///
    /// - Parameter cursor: A pointer to a page of results to fetch.
    public func listPredictions<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        cursor: Pagination.Cursor? = nil
    ) async throws -> Pagination.Page<Prediction<Input, Output>>
    {
        return try await fetch(.get, "predictions", cursor: cursor)
    }

    /// Get a prediction
    ///
    /// - Parameter id: The ID of the prediction you want to fetch.
    public func getPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        id: Prediction.ID
    ) async throws -> Prediction<Input, Output> {
        return try await fetch(.get, "predictions/\(id)")
    }

    /// Cancel a prediction
    ///
    /// - Parameter id: The ID of the prediction you want to cancel.
    public func cancelPrediction<Input: Codable, Output: Codable>(
        _ type: Prediction<Input, Output>.Type = AnyPrediction.self,
        id: Prediction.ID
    ) async throws -> Prediction<Input, Output> {
        return try await fetch(.post, "predictions/\(id)/cancel")
    }

    // MARK: -

    /// List public models
    /// - Parameters:
    ///     - Parameter cursor: A pointer to a page of results to fetch.
    public func listModels(cursor: Pagination.Cursor? = nil)
        async throws -> Pagination.Page<Model>
    {
        return try await fetch(.get, "models", cursor: cursor)
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

    /// Create a model
    ///
    /// - Parameters:
    ///   - owner: The name of the user or organization that will own the model. This must be the same as the user or organization that is making the API request. In other words, the API token used in the request must belong to this user or organization.
    ///   - name: The name of the model. This must be unique among all models owned by the user or organization.
    ///   - visibility: Whether the model should be public or private. A public model can be viewed and run by anyone, whereas a private model can be viewed and run only by the user or organization members that own the model.
    ///   - hardware: The SKU for the hardware used to run the model. Possible values can be found by calling ``listHardware()``.
    ///   - description: A description of the model.
    ///   - githubURL: A URL for the model's source code on GitHub.
    ///   - paperURL: A URL for the model's paper.
    ///   - licenseURL: A URL for the model's license.
    ///   - coverImageURL: A URL for the model's cover image. This should be an image file.
    public func createModel(
        owner: String,
        name: String,
        visibility: Model.Visibility,
        hardware: Hardware.ID,
        description: String? = nil,
        githubURL: URL? = nil,
        paperURL: URL? = nil,
        licenseURL: URL? = nil,
        coverImageURL: URL? = nil
    ) async throws -> Model
    {
        var params: [String: Value] = [
            "owner": "\(owner)",
            "name": "\(name)",
            "visibility": "\(visibility.rawValue)",
            "hardware": "\(hardware)"
        ]

        if let description {
            params["description"] = "\(description)"
        }

        if let githubURL {
            params["github_url"] = "\(githubURL)"
        }

        if let paperURL {
            params["paper_url"] = "\(paperURL)"
        }

        if let licenseURL {
            params["license_url"] = "\(licenseURL)"
        }

        if let coverImageURL {
            params["cover_image_url"] = "\(coverImageURL)"
        }

        return try await fetch(.post, "models", params: params)
    }

    // MARK: -

    /// List hardware available for running a model on Replicate.
    ///
    /// - Returns: An array of hardware.
    public func listHardware() async throws -> [Hardware] {
        return try await fetch(.get, "hardware")
    }


    // MARK: -

    @available(*, deprecated, renamed: "listModelVersions(_:cursor:)")
    public func getModelVersions(_ id: Model.ID,
                                 cursor: Pagination.Cursor? = nil)
        async throws -> Pagination.Page<Model.Version>
    {
        return try await listModelVersions(id, cursor: cursor)
    }

    /// List model versions
    ///
    /// - Parameters:
    ///    - id: The model identifier, comprising
    ///          the name of the user or organization that owns the model and
    ///          the name of the model.
    ///          For example, "stability-ai/stable-diffusion".
    ///    - cursor: A pointer to a page of results to fetch.
    public func listModelVersions(_ id: Model.ID,
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

    // MARK: -

    /// List collections of models
    /// - Parameters:
    ///     - Parameter cursor: A pointer to a page of results to fetch.
    public func listModelCollections(cursor: Pagination.Cursor? = nil)
        async throws -> Pagination.Page<Model.Collection>
    {
        return try await fetch(.get, "collections")
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

    /// Train a model on Replicate.
    ///
    /// To find out which models can be trained,
    /// check out the [trainable language models collection](https://replicate.com/collections/trainable-language-models).
    ///
    /// - Parameters:
    ///    - model:
    ///         The base model used to train a new version.
    ///    - id:
    ///         The ID of the base model version
    ///         that you're using to train a new model version.
    ///
    ///         You can get your model's versions using the API,
    ///         or find them on the website by clicking
    ///         the "Versions" tab on the Replicate model page,
    ///         e.g. replicate.com/replicate/hello-world/versions,
    ///         then copying the full SHA256 hash from the URL.
    ///
    ///         The version ID is the same as the Docker image ID
    ///         that's created when you build your model.
    ///    - destination:
    ///        The desired model to push to in the format `{owner}/{model_name}`.
    ///        This should be an existing model owned by
    ///        the user or organization making the API request.
    ///    - input:
    ///        An object containing inputs to the
    ///        Cog model's `train()` function.
    ///    - webhook:
    ///         A webhook that is called when the training has completed.
    ///
    ///         It will be a `POST` request where
    ///         the request body is the same as
    ///         the response body of the get training endpoint.
    ///         If there are network problems,
    ///         we will retry the webhook a few times,
    ///         so make sure it can be safely called more than once.
    public func createTraining<Input: Codable>(
        _ type: Training<Input>.Type = AnyTraining.self,
        model: Model.ID,
        version: Model.Version.ID,
        destination: Model.ID,
        input: Input,
        webhook: Webhook? = nil
    ) async throws -> Training<Input>
    {
        var params: [String: Value] = [
            "destination": "\(destination)",
            "input": try Value(input)
        ]

        if let webhook {
            params["webhook"] = "\(webhook.url.absoluteString)"
            params["webhook_events_filter"] = .array(webhook.events.map { "\($0.rawValue)" })
        }

        return try await fetch(.post, "models/\(model)/versions/\(version)/trainings", params: params)
    }

    @available(*, deprecated, renamed: "listTrainings(_:cursor:)")
    public func getTrainings<Input: Codable>(
        _ type: Training<Input>.Type = AnyTraining.self,
        cursor: Pagination.Cursor? = nil
    ) async throws -> Pagination.Page<Training<Input>>
    {
        return try await listTrainings(type, cursor: cursor)
    }

    /// List trainings
    ///
    /// - Parameter cursor: A pointer to a page of results to fetch.
    public func listTrainings<Input: Codable>(
        _ type: Training<Input>.Type = AnyTraining.self,
        cursor: Pagination.Cursor? = nil
    ) async throws -> Pagination.Page<Training<Input>>
    {
        return try await fetch(.get, "trainings", cursor: cursor)
    }

    /// Get a training
    ///
    /// - Parameter id: The ID of the training you want to fetch.
    public func getTraining<Input: Codable>(
        _ type: Training<Input>.Type = AnyTraining.self,
        id: Training.ID
    ) async throws -> Training<Input>
    {
        return try await fetch(.get, "trainings/\(id)")
    }

    /// Cancel a training
    ///
    /// - Parameter id: The ID of the training you want to cancel.
    public func cancelTraining<Input: Codable>(
        _ type: Training<Input>.Type = AnyTraining.self,
        id: Training.ID
    ) async throws -> Training<Input>
    {
        return try await fetch(.post, "trainings/\(id)/cancel")
    }

    // MARK: -
    
    /// Get the current account
    public func getCurrentAccount() async throws -> Account {
        return try await fetch(.get, "account")
    }

    // MARK: -

    /// Get a deployment
    ///
    /// - Parameters:
    ///    - id: The deployment identifier, comprising
    ///          the name of the user or organization that owns the deployment and
    ///          the name of the deployment.
    ///          For example, "replicate/my-app-image-generator".
    public func getDeployment(_ id: Deployment.ID)
        async throws -> Deployment
    {
        return try await fetch(.get, "deployments/\(id)")
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
        var params: [String: Value]? = nil
        if let cursor {
            params = ["cursor": "\(cursor)"]
        }

        let request = try createRequest(method: method, path: path, params: params)
        return try await sendRequest(request)
    }

    private func fetch<T: Decodable>(_ method: Method,
                                     _ path: String,
                                     params: [String: Value]? = nil)
    async throws -> T {
        let request = try createRequest(method: method, path: path, params: params)
        return try await sendRequest(request)
    }

    private func createRequest(method: Method, path: String, params: [String: Value]? = nil) throws -> URLRequest {
        var urlComponents = URLComponents(string: self.baseURLString.appending(path))
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
        case .query:
            if let params, let queryString = params["query"] {
                httpBody = queryString.description.data(using: .utf8)
            }
        }

        guard let url = urlComponents?.url else {
            throw Error(detail: "invalid request \(method) \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let httpBody {
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        return request
    }

    private func sendRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
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

extension Client {
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
}

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

extension Client {
    /// A policy for how often a client should retry a request.
    public struct RetryPolicy: Equatable, Sequence {
        /// A strategy used to determine how long to wait between retries.
        public enum Strategy: Hashable {
            /// Wait for a constant interval.
            ///
            /// This strategy implements constant backoff with jitter
            /// as described by the equation:
            ///
            /// $$
            /// t = d + R([-j/2, j/2])
            /// $$
            ///
            /// - Parameters:
            ///   - duration: The constant interval ($d$).
            ///   - jitter: The amount of random jitter ($j$).
            case constant(duration: TimeInterval = 2.0,
                          jitter: Double = 0.0)

            /// Wait for an exponentially increasing interval.
            ///
            /// This strategy implements exponential backoff with jitter
            /// as described by the equation:
            ///
            /// $$
            /// t = b^c + R([-j/2, j/2])
            /// $$
            ///
            /// - Parameters:
            ///   - base: The power base ($b$).
            ///   - multiplier: The power exponent ($c$).
            ///   - jitter: The amount of random jitter ($j$).
            case exponential(base: TimeInterval = 2.0,
                             multiplier: Double = 2.0,
                             jitter: Double = 0.5)
        }

        /// The strategy used to determine how long to wait between retries.
        public let strategy: Strategy

        /// The total maximum amount of time to retry requests.
        public let timeout: TimeInterval?

        /// The maximum amount of time between requests.
        public let maximumInterval: TimeInterval?

        /// The maximum number of requests to make.
        public let maximumRetries: Int?

        /// The default retry policy.
        static let `default` = RetryPolicy(strategy: .exponential(),
                                           timeout: 300.0,
                                           maximumInterval: 30.0,
                                           maximumRetries: 10)

        /// Creates a new retry policy.
        ///
        /// - Parameters:
        ///   - strategy: The strategy used to determine how long to wait between retries.
        ///   - timeout: The total maximum amount of time to retry requests.
        ///              Must be greater than zero, if specified.
        ///   - maximumInterval: The maximum amount of time between requests.
        ///                      Must be greater than zero, if specified.
        ///   - maximumRetries: The maximum number of requests to make.
        ///                     Must be greater than zero, if specified.
        public init(strategy: Strategy,
                    timeout: TimeInterval?,
                    maximumInterval: TimeInterval?,
                    maximumRetries: Int?)
        {
            precondition(timeout ?? .greatestFiniteMagnitude > 0)
            precondition(maximumInterval ?? .greatestFiniteMagnitude > 0)
            precondition(maximumRetries ?? .max > 0)

            self.strategy = strategy
            self.timeout = timeout
            self.maximumInterval = maximumInterval
            self.maximumRetries = maximumRetries
        }

        /// An instantiation of a retry policy.
        ///
        /// This type satisfies a requirement for `RetryPolicy`
        /// to conform to the `Sequence` protocol.
        public struct Retrier: IteratorProtocol {
            /// The number of retry attempts made.
            public private(set) var retries: Int = 0

            /// The retry policy.
            public let policy: RetryPolicy

            /// The random number generator used to create random values.
            private var randomNumberGenerator: any RandomNumberGenerator

            /// A time after which no delay values are produced, if any.
            public let deadline: DispatchTime?

            /// Creates a new instantiation of a retry policy.
            ///
            /// - Parameters:
            ///   - policy: The retry policy.
            ///   - randomNumberGenerator: The random number generator used to create random values.
            ///   - deadline: A time after which no delay values are produced, if any.
            init(policy: RetryPolicy,
                 randomNumberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator(),
                 deadline: DispatchTime?)
            {
                self.policy = policy
                self.randomNumberGenerator = randomNumberGenerator
                self.deadline = deadline
            }

            /// Returns the next delay amount, or `nil`.
            public mutating func next() -> TimeInterval? {
                guard policy.maximumRetries.flatMap({ $0 > retries }) ?? true else { return nil }
                guard deadline.flatMap({ $0 > .now() }) ?? true else { return nil }

                defer { retries += 1 }

                let delay: TimeInterval
                switch policy.strategy {
                case .constant(let base, let jitter):
                    delay = base + Double.random(jitter: jitter, using: &randomNumberGenerator)
                case .exponential(let base, let multiplier, let jitter):
                    delay = base * (pow(multiplier, Double(retries))) + Double.random(jitter: jitter, using: &randomNumberGenerator)
                }

                return delay.clamped(to: 0...(policy.maximumInterval ?? .greatestFiniteMagnitude))
            }
        }

        // Returns a new instantiation of the retry policy.
        public func makeIterator() -> Retrier {
            return Retrier(policy: self,
                           deadline: timeout.flatMap {
                            .now().advanced(by: .nanoseconds(Int($0 * 1e+9)))
                           })
        }
    }
}

// MARK: -

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime,
                                   .withFractionalSeconds]

        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try again without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]

        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        return date
    }
}

private extension Double {
    static func random<T>(jitter amount: Double,
                          using generator: inout T) -> Double
        where T : RandomNumberGenerator
    {
        guard !amount.isZero else { return 0.0 }
        return Double.random(in: (-amount / 2)...(amount / 2))
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
