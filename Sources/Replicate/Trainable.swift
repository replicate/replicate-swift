/// A type that can train new model versions with known inputs.
public protocol Trainable {
    /// The type of the input to the model.
    associatedtype Input: Codable

    /// The ID of the model.
    static var modelID: Model.ID { get }

    /// The ID of the model version.
    static var versionID: Model.Version.ID { get }
}

// MARK: - Default Implementations

extension Trainable {
    /// The type of training created by the model
    public typealias Training = Replicate.Training<Input>

    /// Trains a new model on Replicate.
    ///
    /// - Parameters:
    ///     - client: The client used to make API requests.
    ///     - destination: The desired model to push to
    ///                    in the format `{owner}/{model_name}`.
    ///     - input: The input passed to the model.
    public static func train(
        with client: Client,
        destination: Model.ID,
        input: Input
    ) async throws -> Training
    {
        return try await client.createTraining(Training.self,
                                               version: Self.versionID,
                                               destination: destination,
                                               input: input)
    }
}
