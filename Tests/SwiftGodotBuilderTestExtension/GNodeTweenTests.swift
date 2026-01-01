// GNodeTweenTests.swift
// Runtime tests for GNode+Tween modifiers

import SwiftGodot
import SwiftGodotBuilder

struct GNodeTweenTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testTweenToggleVector2", testTweenToggleVector2),
      test("testTweenWhenModifier", testTweenWhenModifier),
      test("testTweenOnChangeModifier", testTweenOnChangeModifier),
      test("testTweenChaining", testTweenChaining),
    ]
  }

  func testTweenToggleVector2() {
    let isActive = GState(wrappedValue: false)

    // Test the property-based tweenToggle API using TweenProp.Scale
    let node = Node2D$()
      .tweenToggle(isActive, TweenProp.Scale.self,
        whenTrue: [1.2, 1.2], whenFalse: [1.0, 1.0],
        duration: 0.1)
      .toNode()

    // Toggle on
    isActive.wrappedValue = true

    // State changed, animation should be triggered
    XCTAssertTrue(isActive.wrappedValue, "State should be true")
  }

  func testTweenWhenModifier() {
    let condition = GState(wrappedValue: false)
    var otherwiseCalled = false

    let _ = Node2D$()
      .tweenWhen(condition, equals: true, { _ in
        // match handler
      }, otherwise: { _ in
        otherwiseCalled = true
      })
      .toNode()

    // Initially false - otherwise should be called
    XCTAssertTrue(otherwiseCalled, "Otherwise should be called when condition is false")

    // Set condition to true
    condition.wrappedValue = true

    // On next observation, matchCalled should be true
    XCTAssertTrue(condition.wrappedValue, "Condition should be true")
  }

  func testTweenOnChangeModifier() {
    let value = GState(wrappedValue: 0)
    var lastValue = 0

    let _ = Node2D$()
      .tweenOnChange(value) { _, newValue in
        lastValue = newValue
      }
      .toNode()

    value.wrappedValue = 1
    value.wrappedValue = 2
    value.wrappedValue = 3

    // Each change should trigger the handler
    XCTAssertEqual(lastValue, 3, "Should receive latest value")
  }

  func testTweenChaining() {
    let state = GState(wrappedValue: false)

    // Test that tween modifiers can be chained with other modifiers
    let node: Node2D = Node2D$()
      .position([50, 50])
      .tweenToggle(state, TweenProp.Scale.self,
        whenTrue: [1.2, 1.2], whenFalse: [1.0, 1.0],
        duration: 0.1)
      .scale([2, 2])
      .toNode()

    // Verify other modifiers still work
    assertApproxEqual(node.position.x, 50, "Position should be set")
    assertApproxEqual(node.scale.x, 2, "Scale should be set")
  }
}
