import Foundation

public extension Data {
    func uriEncoded(mimeType: String?) -> String {
        return "data:\(mimeType ?? "");base64,\(base64EncodedString())"
    }
}
