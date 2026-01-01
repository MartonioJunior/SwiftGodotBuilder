// Assertions.swift
// XCTest-compatible assertion functions for Godot runtime tests

import SwiftGodot

// MARK: - Core Assertions

/// Assert that a condition is true
public func assertTrue(
  _ condition: Bool,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard !condition else { return }
  let msg = message.isEmpty ? "Expected true, got false" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a condition is false
public func assertFalse(
  _ condition: Bool,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  assertTrue(!condition, message.isEmpty ? "Expected false, got true" : message, file: file, line: line)
}

/// Assert that two values are equal
public func assertEqual<T: Equatable>(
  _ a: T?,
  _ b: T?,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a != b else { return }
  let msg = message.isEmpty ? "Expected \(String(describing: b)), got \(String(describing: a))" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that two values are not equal
public func assertNotEqual<T: Equatable>(
  _ a: T?,
  _ b: T?,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a == b else { return }
  let msg = message.isEmpty ? "Expected values to differ, but both were \(String(describing: a))" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a value is nil
public func assertNil<T>(
  _ value: T?,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard value != nil else { return }
  let msg = message.isEmpty ? "Expected nil, got \(String(describing: value))" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a value is not nil
public func assertNotNil<T>(
  _ value: T?,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard value == nil else { return }
  let msg = message.isEmpty ? "Expected non-nil value, got nil" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Unconditionally fail the test
public func fail(
  _ message: String = "Test failed",
  file: StaticString = #file,
  line: UInt = #line
) {
  TestContext.current?.recordFailure(
    message: message,
    file: String(describing: file),
    line: Int(line)
  )
}

// MARK: - Comparison Assertions

/// Assert that a value is greater than another
public func assertGreaterThan<T: Comparable>(
  _ a: T,
  _ b: T,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a <= b else { return }
  let msg = message.isEmpty ? "Expected \(a) > \(b)" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a value is less than another
public func assertLessThan<T: Comparable>(
  _ a: T,
  _ b: T,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a >= b else { return }
  let msg = message.isEmpty ? "Expected \(a) < \(b)" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a value is greater than or equal to another
public func assertGreaterThanOrEqual<T: Comparable>(
  _ a: T,
  _ b: T,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a < b else { return }
  let msg = message.isEmpty ? "Expected \(a) >= \(b)" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

/// Assert that a value is less than or equal to another
public func assertLessThanOrEqual<T: Comparable>(
  _ a: T,
  _ b: T,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a > b else { return }
  let msg = message.isEmpty ? "Expected \(a) <= \(b)" : message
  TestContext.current?.recordFailure(
    message: msg,
    file: String(describing: file),
    line: Int(line)
  )
}

// MARK: - Approximate Equality (for floating point)

/// Asserts approximate equality of two floating point values
public func assertApproxEqual(
  _ a: Float?,
  _ b: Float?,
  epsilon: Float = 0.00001,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a != b else { return }
  guard let a = a, let b = b else {
    assertEqual(a, b, message, file: file, line: line)
    return
  }

  let tolerance: Float = max(epsilon * abs(a), epsilon)
  if abs(a - b) > tolerance {
    let msg = message.isEmpty ? "Expected \(b) +/- \(tolerance), got \(a)" : message
    TestContext.current?.recordFailure(
      message: msg,
      file: String(describing: file),
      line: Int(line)
    )
  }
}

/// Asserts approximate equality of two Double values
public func assertApproxEqual(
  _ a: Double?,
  _ b: Double?,
  epsilon: Double = 0.00001,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard a != b else { return }
  guard let a = a, let b = b else {
    assertEqual(a, b, message, file: file, line: line)
    return
  }

  let tolerance: Double = max(epsilon * abs(a), epsilon)
  if abs(a - b) > tolerance {
    let msg = message.isEmpty ? "Expected \(b) +/- \(tolerance), got \(a)" : message
    TestContext.current?.recordFailure(
      message: msg,
      file: String(describing: file),
      line: Int(line)
    )
  }
}

/// Asserts approximate equality of two Vector2
public func assertApproxEqual(
  _ a: Vector2?,
  _ b: Vector2?,
  _ message: String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard let a = a, let b = b else {
    assertEqual(a, b, message, file: file, line: line)
    return
  }
  assertApproxEqual(a.x, b.x, "X mismatch. " + message, file: file, line: line)
  assertApproxEqual(a.y, b.y, "Y mismatch. " + message, file: file, line: line)
}

// MARK: - XCTest Compatibility Aliases

public func XCTAssertTrue(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertTrue(condition, message, file: file, line: line)
}

public func XCTAssertFalse(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertFalse(condition, message, file: file, line: line)
}

public func XCTAssertEqual<T: Equatable>(_ a: T?, _ b: T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertEqual(a, b, message, file: file, line: line)
}

public func XCTAssertNotEqual<T: Equatable>(_ a: T?, _ b: T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertNotEqual(a, b, message, file: file, line: line)
}

public func XCTAssertNil<T>(_ value: T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertNil(value, message, file: file, line: line)
}

public func XCTAssertNotNil<T>(_ value: T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertNotNil(value, message, file: file, line: line)
}

public func XCTFail(_ message: String = "Test failed", file: StaticString = #file, line: UInt = #line) {
  fail(message, file: file, line: line)
}

public func XCTAssertGreaterThan<T: Comparable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertGreaterThan(a, b, message, file: file, line: line)
}

public func XCTAssertLessThan<T: Comparable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertLessThan(a, b, message, file: file, line: line)
}

public func XCTAssertGreaterThanOrEqual<T: Comparable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertGreaterThanOrEqual(a, b, message, file: file, line: line)
}

public func XCTAssertLessThanOrEqual<T: Comparable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  assertLessThanOrEqual(a, b, message, file: file, line: line)
}
