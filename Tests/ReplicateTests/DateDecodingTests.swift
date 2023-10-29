import XCTest
@testable import Replicate

struct Value: Decodable {
    let date: Date
}

final class DateDecodingTests: XCTestCase {
    func testISO8601Timestamp() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        let timestamp = "2023-10-29T01:23:45Z"
        let json = #"{"date": "\#(timestamp)"}"#
        let value = try decoder.decode(Value.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(value.date.timeIntervalSince1970, 1698542625)
    }

    func testISO8601TimestampWithFractionalSeconds() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        let timestamp = "2023-10-29T01:23:45.678900Z"
        let json = #"{"date": "\#(timestamp)"}"#
        let value = try decoder.decode(Value.self, from: json.data(using: .utf8)!)
        XCTAssertEqualWithAccuracy(value.date.timeIntervalSince1970, 1698542625.678, accuracy: 0.1)
    }
}
