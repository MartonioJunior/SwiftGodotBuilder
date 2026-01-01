// GNodeEventsTests.swift
// Runtime tests for GNode+Events modifiers

import SwiftGodot
import SwiftGodotBuilder

// Test events for GNode event modifiers
enum NodeTestEvent: EmittableEvent, Equatable {
  case ping
  case data(Int)
  case action(String)
}

struct GNodeEventsTests: TestSuite {
  static var registeredTypes: [Object.Type] { [GEventRelay.self] }

  var allTests: [TestInvocation] {
    [
      test("testOnEventModifierCreatesNode", testOnEventModifierCreatesNode),
      test("testOnEventChaining", testOnEventChaining),
      test("testOnEventWithMatchCreatesNode", testOnEventWithMatchCreatesNode),
    ]
  }

  func testOnEventModifierCreatesNode() {
    // Test that onEvent modifier produces a valid node
    let node = Node2D$()
      .onEvent(NodeTestEvent.self) { _, _ in }
      .toNode()

    XCTAssertNotNil(node, "onEvent modifier should produce a node")
  }

  func testOnEventChaining() {
    // Test that onEvent can be chained with other modifiers
    let node = Node2D$()
      .position([10, 20])
      .onEvent(NodeTestEvent.self) { _, _ in }
      .scale([2, 2])
      .toNode()

    if let node2d = node as? Node2D {
      assertApproxEqual(node2d.position.x, 10, "Position X should be set")
      assertApproxEqual(node2d.scale.x, 2, "Scale X should be set")
    }
  }

  func testOnEventWithMatchCreatesNode() {
    // Test that onEvent with match closure produces a valid node
    let node = Node2D$()
      .onEvent(NodeTestEvent.self, match: { event in
        if case .ping = event { return true }
        return false
      }) { _, _ in }
      .toNode()

    XCTAssertNotNil(node, "onEvent with match should produce a node")
  }
}
