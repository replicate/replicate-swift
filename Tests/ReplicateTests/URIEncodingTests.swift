import XCTest
@testable import Replicate

final class URIEncodingTests: XCTestCase {
    func testDataURIEncoding() throws {
        let string = "Hello, World!"
        let base64Encoded = "SGVsbG8sIFdvcmxkIQ=="
        XCTAssertEqual(string.data(using: .utf8)?.base64EncodedString(), base64Encoded)

        let mimeType = "text/plain"
        XCTAssertEqual(string.data(using: .utf8)?.uriEncoded(mimeType: mimeType),
                       "data:\(mimeType);base64,\(base64Encoded)")
    }
}
