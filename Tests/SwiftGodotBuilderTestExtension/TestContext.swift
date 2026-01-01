// TestContext.swift
// Tracks test execution state and failures

import Foundation

/// Context for a currently executing test
public final class TestContext {
  /// The current test context
  public static var current: TestContext?

  /// Name of the current test
  public let testName: String

  /// Recorded failures
  public private(set) var failures: [TestFailure] = []

  /// Whether this test has failed
  public var hasFailed: Bool { !failures.isEmpty }

  public init(testName: String) {
    self.testName = testName
  }

  public func recordFailure(message: String, file: String, line: Int) {
    let failure = TestFailure(message: message, file: file, line: line)
    failures.append(failure)
  }
}

/// A recorded test failure
public struct TestFailure: Codable {
  public let message: String
  public let file: String
  public let line: Int
}
