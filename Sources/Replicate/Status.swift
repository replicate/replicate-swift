/// The status of the prediction or training.
public enum Status: String, Hashable, Codable {
    /// The prediction or training is starting up.
    /// If this status lasts longer than a few seconds,
    /// then it's typically because a new worker is being started to run the prediction.
    case starting

    /// The `predict()` or `train()` method of the model is currently running.
    case processing

    /// The prediction or training completed successfully.
    case succeeded

    /// The prediction or training encountered an error during processing.
    case failed

    /// The prediction or training was canceled by the user.
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
