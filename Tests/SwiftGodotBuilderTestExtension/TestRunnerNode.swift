// TestRunnerNode.swift
// Godot node that runs all registered tests

import Foundation
import SwiftGodot

/// A Node that runs all registered tests when added to the scene tree.
@Godot
public class TestRunnerNode: Node {
  private let resultsPath = "res://test_results.json"

  /// Test filter from environment variable
  private var testFilter: TestFilter? {
    guard let filter = ProcessInfo.processInfo.environment["SWIFTGODOT_TEST_FILTER"],
        !filter.isEmpty else {
      return nil
    }
    return TestFilter(filter)
  }

  /// All test suites to run - add your test suites here
  private let suites: [any TestSuite] = [
    ActorDefenseTests(),
    ActorPhysicsStateTests(),
    ActorPhysicsConfigTests(),
    GStateTests(),
    BehaviorMachineTests(),
    EventBusTests(),
    ObjectPoolTests(),
    StoreTests(),
    FacingTests(),
    ParticleConfigTests(),
    AnimPropertyTests(),
    ActionsTests(),
    AbilityTests(),
    DialogTests(),
    GSwitchTests(),
    GNodeEventsTests(),
    GNodeSignalsTests(),
    GNodeTweenTests(),
    GViewTests(),
  ]

  override public func _ready() {
    GD.print("=".repeated(60))
    GD.print("SwiftGodotBuilder Runtime Tests")
    GD.print("=".repeated(60))

    let results = runAllTests()
    writeResults(results)

    GD.print("-".repeated(60))
    GD.print("Summary: \(results.summary.passed) passed, \(results.summary.failed) failed, \(results.summary.skipped) skipped")
    GD.print("Total time: \(formatDuration(results.duration))")
    GD.print("=".repeated(60))

    let exitCode = results.summary.failed > 0 ? 1 : 0

    // Delay quit to allow Godot to flush the delete queue first
    // This prevents crashes during cleanup when Swift objects are freed
    Engine.onNextFrame { [weak self] in
      Engine.onNextFrame {
        self?.getTree()?.quit(exitCode: Int32(exitCode))
      }
    }
  }

  // MARK: - Test Execution

  private func runAllTests() -> TestResults {
    var suiteResults: [TestSuiteResult] = []
    let startTime = Date().timeIntervalSince1970

    let filter = testFilter
    let filteredSuites: [any TestSuite]
    if let filter {
      filteredSuites = suites.filter { filter.matchesSuite(type(of: $0).name) }
      GD.print("Running filtered tests: \(filter.suiteName)\(filter.testName.map { ".\($0)" } ?? "")...")
    } else {
      filteredSuites = suites
      GD.print("Running \(suites.count) test suites...")
    }

    for suite in filteredSuites {
      let suiteResult = runSuite(suite, filter: filter)
      suiteResults.append(suiteResult)
    }

    let duration = Date().timeIntervalSince1970 - startTime
    return TestResults(suites: suiteResults, duration: duration)
  }

  private func runSuite(_ suite: any TestSuite, filter: TestFilter? = nil) -> TestSuiteResult {
    let suiteType = type(of: suite)
    let suiteName = suiteType.name
    GD.printRich("[color=blue][b]\(suiteName)[/b][/color]")

    // Register types needed by this suite
    for subclass in suiteType.registeredTypes {
      register(type: subclass)
    }

    // Run test methods
    let allTests = suite.allTests
    let tests = filter.map { f in allTests.filter { f.matchesTest($0.name) } } ?? allTests
    var testResults: [TestCaseResult] = []

    for test in tests {
      GD.printRich("  [color=gray]\(test.name)[/color]")
      let result = runTest(test: test)
      testResults.append(result)

      if let failure = result.failure {
        GD.printRich("  [color=red][b]FAILED:[/b] \(failure.message)[/color]")
        GD.printRich("  [color=red]  at \(failure.file):\(failure.line)[/color]")
      } else {
        GD.printRich("  [color=green]PASSED[/color]")
      }
    }

    // Unregister types
    for subclass in suiteType.registeredTypes.reversed() {
      unregister(type: subclass)
    }

    GD.print("")
    return TestSuiteResult(name: suiteName, tests: testResults)
  }

  private func runTest(test: TestInvocation) -> TestCaseResult {
    let context = TestContext(testName: test.name)
    TestContext.current = context

    let startTime = Date().timeIntervalSince1970
    test.run()
    let duration = Date().timeIntervalSince1970 - startTime

    TestContext.current = nil

    let status: TestStatus = context.hasFailed ? .failed : .passed

    return TestCaseResult(
      name: test.name,
      status: status,
      duration: duration,
      failure: context.failures.first
    )
  }

  // MARK: - Results Output

  private func writeResults(_ results: TestResults) {
    guard let jsonString = results.toJSON() else {
      GD.printErr("Failed to encode test results to JSON")
      return
    }

    let file = FileAccess.open(path: resultsPath, flags: .write)
    if let file {
      _ = file.storeString(jsonString)
      file.close()
      GD.print("Results written to: \(resultsPath)")
    } else {
      GD.printErr("Failed to open results file: \(resultsPath)")
    }
  }

  private func formatDuration(_ seconds: Double) -> String {
    if seconds >= 1.0 {
      return String(format: "%.2fs", seconds)
    } else {
      return String(format: "%.2fms", seconds * 1000)
    }
  }
}

private extension String {
  func repeated(_ times: Int) -> String {
    String(repeating: self, count: times)
  }
}

/// Filter for running specific tests
struct TestFilter {
  let suiteName: String
  let testName: String?

  init(_ filter: String) {
    let parts = filter.split(separator: ".", maxSplits: 1)
    suiteName = String(parts[0])
    testName = parts.count > 1 ? String(parts[1]) : nil
  }

  func matchesSuite(_ name: String) -> Bool {
    name == suiteName
  }

  func matchesTest(_ name: String) -> Bool {
    testName == nil || testName == name
  }
}
