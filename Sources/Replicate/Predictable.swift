/// A type that can make predictions with known inputs and outputs.
public protocol Predictable {
    /// The type of the input to the model.
    associatedtype Input: Codable

    /// The type of the output from the model.
    associatedtype Output: Codable

    /// The ID of the model.
    static var modelID: Model.ID { get }

    /// The ID of the model version.
    static var versionID: Model.Version.ID { get }
}

// MARK: - Default Implementations

extension Predictable {
    /// The type of prediction created by the model
    public typealias Prediction = Replicate.Prediction<Input, Output>

    /// Creates a prediction.
    ///
    /// - Parameters:
    ///     - client: The client used to make API requests.
    ///     - input: The input passed to the model.
    ///     - wait:
    ///         If set to `true`,
    ///         this method refreshes the prediction until it completes
    ///         (``Prediction/status`` is `.succeeded` or `.failed`).
    ///         By default, this is `false`,
    ///         and this method returns the prediction object encoded
    ///         in the original creation response
    ///         (``Prediction/status`` is `.starting`).
    public static func predict(
        with client: Client,
        input: Input,
        webhook: Webhook? = nil,
        wait: Bool = false
    ) async throws -> Prediction {
        return try await client.createPrediction(Prediction.self,
                                                 version: Self.versionID,
                                                 input: input,
                                                 webhook: webhook,
                                                 wait: wait)
    }
}
