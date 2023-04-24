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

    func testISURIEncoded() throws {
        XCTAssertTrue(Data.isURIEncoded(string: "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="))
        XCTAssertFalse(Data.isURIEncoded(string: "Hello, World!"))
        XCTAssertFalse(Data.isURIEncoded(string: ""))
    }

    func testDecodeURIEncoded() throws {
        let encoded = "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="
        guard case let (mimeType, data)? = Data.decode(uriEncoded: encoded) else {
            return XCTFail("failed to decode data URI")
        }

        XCTAssertEqual(mimeType, "text/plain")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Hello, World!")
    }
}
