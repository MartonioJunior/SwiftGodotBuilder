// GNodeSignalsTests.swift
// Runtime tests for GNode+Signals modifiers

import SwiftGodot
import SwiftGodotBuilder

struct GNodeSignalsTests: TestSuite {
  static var registeredTypes: [Object.Type] { [GProcessRelay.self] }

  var allTests: [TestInvocation] {
    [
      test("testOnSignalWithKeyPath", testOnSignalWithKeyPath),
      test("testOnSignalChaining", testOnSignalChaining),
      test("testOnReadyModifier", testOnReadyModifier),
      test("testOnSignalMultipleTriggers", testOnSignalMultipleTriggers),
    ]
  }

  func testOnSignalWithKeyPath() {
    var called = false

    // Use keypath syntax for signals
    let button = Button$()
      .onSignal(\.pressed) { _ in
        called = true
      }
      .toNode()

    // Emit the signal programmatically
    button.emitSignal("pressed")

    XCTAssertTrue(called, "onSignal should handle zero-argument signals via keypath")
  }

  func testOnSignalChaining() {
    var pressCount = 0
    var focusCount = 0

    let button = Button$()
      .text("Test")
      .onSignal(\.pressed) { _ in
        pressCount += 1
      }
      .onSignal(\.focusEntered) { _ in
        focusCount += 1
      }
      .toNode()

    button.emitSignal("pressed")
    button.emitSignal("focus_entered")

    XCTAssertEqual(pressCount, 1, "First signal handler should work")
    XCTAssertEqual(focusCount, 1, "Second signal handler should work with chaining")
  }

  func testOnReadyModifier() {
    // onReady uses GProcessRelay which requires actual tree lifecycle
    // Test that the modifier produces a valid node with a relay child
    let node = Node2D$()
      .onReady { _ in
        // Handler stored for later
      }
      .toNode()

    // Verify the relay was attached
    let relay = node.getNodeOrNull(path: NodePath("__GProcessRelay__"))
    XCTAssertNotNil(relay, "onReady should attach a GProcessRelay child")
  }

  func testOnSignalMultipleTriggers() {
    var count = 0

    let button = Button$()
      .onSignal(\.pressed) { _ in
        count += 1
      }
      .toNode()

    button.emitSignal("pressed")
    button.emitSignal("pressed")
    button.emitSignal("pressed")

    XCTAssertEqual(count, 3, "Signal handler should be called each time signal is emitted")
  }
}
