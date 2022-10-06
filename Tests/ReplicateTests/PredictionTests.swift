import XCTest
@testable import Replicate

final class PredictionTests: XCTestCase {
    var client = Client.valid

    static override func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    func testWait() async throws {
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        var prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        XCTAssertEqual(prediction.status, .starting)

        try await prediction.wait(with: client)
        XCTAssertEqual(prediction.status, .succeeded)
    }

    func testCancel() async throws {
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        var prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        XCTAssertEqual(prediction.status, .starting)

        try await prediction.cancel(with: client)
        XCTAssertEqual(prediction.status, .canceled)
    }
}
