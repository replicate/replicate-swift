import XCTest
@testable import Replicate

final class RetryPolicyTests: XCTestCase {
    func testConstantBackoffStrategy() throws {
        let policy = Client.RetryPolicy(strategy: .constant(duration: 1.0,
                                                            jitter: 0.0),
                                        timeout: nil,
                                        maximumInterval: nil,
                                        maximumRetries: 5)

        XCTAssertEqual(Array(policy), [1.0, 1.0, 1.0, 1.0, 1.0])
    }

    func testExponentialBackoffStrategy() throws {
        let policy = Client.RetryPolicy(strategy: .exponential(base: 1.0,
                                                               multiplier: 2.0,
                                                               jitter: 0.0),
                                        timeout: nil,
                                        maximumInterval: 30.0,
                                        maximumRetries: 7)

        XCTAssertEqual(Array(policy), [1.0, 2.0, 4.0, 8.0, 16.0, 30.0, 30.0])
    }

    func testTimeoutWithDeadline() throws {
        let timeout: TimeInterval = 300.0
        let policy = Client.RetryPolicy(strategy: .constant(),
                                        timeout: timeout,
                                        maximumInterval: nil,
                                        maximumRetries: nil)
        let deadline = policy.makeIterator().deadline

        XCTAssertNotNil(deadline)
        XCTAssertLessThanOrEqual(deadline ?? .distantFuture, DispatchTime.now().advanced(by: .nanoseconds(Int(timeout * 1e+9))))
    }

    func testTimeoutWithoutDeadline() throws {
        let policy = Client.RetryPolicy(strategy: .constant(),
                                        timeout: nil,
                                        maximumInterval: nil,
                                        maximumRetries: nil)
        let deadline = policy.makeIterator().deadline
        
        XCTAssertNil(deadline)
    }

    func testMaximumInterval() throws {
        let maximumInterval: TimeInterval = 30.0
        let policy = Client.RetryPolicy(strategy: .exponential(),
                                        timeout: nil,
                                        maximumInterval: maximumInterval,
                                        maximumRetries: 10)

        XCTAssertGreaterThanOrEqual(maximumInterval, policy.max() ?? .greatestFiniteMagnitude)
    }

    func testMaximumRetries() throws {
        let maximumRetries: Int = 5
        let policy = Client.RetryPolicy(strategy: .constant(),
                                        timeout: nil,
                                        maximumInterval: nil,
                                        maximumRetries: maximumRetries)

        XCTAssertEqual(Array(policy).count, maximumRetries)
    }
}
