// TestResult.swift
// Data structures for test results

import Foundation

/// Status of a test case
public enum TestStatus: String, Codable, Sendable {
  case passed
  case failed
  case skipped
}

/// Result of a single test case
public struct TestCaseResult: Codable, Sendable {
  public let name: String
  public let status: TestStatus
  public let duration: Double
  public let failure: TestFailure?

  public init(name: String, status: TestStatus, duration: Double, failure: TestFailure? = nil) {
    self.name = name
    self.status = status
    self.duration = duration
    self.failure = failure
  }
}

/// Result of a test suite
public struct TestSuiteResult: Codable, Sendable {
  public let name: String
  public let tests: [TestCaseResult]

  public init(name: String, tests: [TestCaseResult]) {
    self.name = name
    self.tests = tests
  }
}

/// Summary of all test results
public struct TestSummary: Codable, Sendable {
  public let passed: Int
  public let failed: Int
  public let skipped: Int

  public init(passed: Int, failed: Int, skipped: Int) {
    self.passed = passed
    self.failed = failed
    self.skipped = skipped
  }
}

/// Complete test results
public struct TestResults: Codable, Sendable {
  public let suites: [TestSuiteResult]
  public let duration: Double
  public let summary: TestSummary

  public init(suites: [TestSuiteResult], duration: Double) {
    self.suites = suites
    self.duration = duration

    var passed = 0, failed = 0, skipped = 0
    for suite in suites {
      for test in suite.tests {
        switch test.status {
        case .passed: passed += 1
        case .failed: failed += 1
        case .skipped: skipped += 1
        }
      }
    }
    self.summary = TestSummary(passed: passed, failed: failed, skipped: skipped)
  }

  public func toJSON() -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(self) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
