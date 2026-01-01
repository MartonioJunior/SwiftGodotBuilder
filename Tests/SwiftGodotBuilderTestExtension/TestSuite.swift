// TestSuite.swift
// Protocol for test suites

import SwiftGodot

/// A test invocation (name + closure)
public struct TestInvocation {
  public let name: String
  public let run: () -> Void

  public init(name: String, run: @escaping () -> Void) {
    self.name = name
    self.run = run
  }
}

/// Protocol for test suites
public protocol TestSuite {
  /// Name of the test suite
  static var name: String { get }

  /// All tests in this suite
  var allTests: [TestInvocation] { get }

  /// Types to register with Godot before running tests
  static var registeredTypes: [Object.Type] { get }

  init()
}

public extension TestSuite {
  static var name: String { String(describing: Self.self) }
  static var registeredTypes: [Object.Type] { [] }
}

/// Helper to create test invocations
public func test(_ name: String, _ body: @escaping () -> Void) -> TestInvocation {
  TestInvocation(name: name, run: body)
}
